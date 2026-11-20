import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift show Value;
import 'package:get/get.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/active_timer_dao.dart';
import '../../data/models/data_mappers.dart';
import '../../domain/entities/domain_entities.dart';
import '../../domain/enums/domain_enums.dart';
import '../../domain/repositories/repositories.dart';
import 'session_notifier.dart';

/// Reliable timestamp-backed timer engine supporting Focus, Stopwatch, and Pomodoro.
///
/// Never relies on decrementing an in-memory integer as truth. All remaining/elapsed
/// calculations derive from persisted UTC timestamps in [ActiveTimerDao].
///
/// Pomodoro rule: a session is one set of `totalCycles` focus phases with a
/// short break between them, followed by one long break. The session is
/// completed when that long break ends (or earlier via [finishEarly]).
/// Only focus time ever counts toward the saved duration.
class TimerEngineService extends GetxService {
  TimerEngineService({
    required SessionRepository sessionRepository,
    required ActiveTimerDao activeTimerDao,
    int Function()? nowMsProvider,
    SessionNotifier notifier = const NoopSessionNotifier(),
  })  : _sessionRepository = sessionRepository,
        _activeTimerDao = activeTimerDao,
        _notifier = notifier,
        _nowMsProvider =
            nowMsProvider ?? (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  /// A forgotten stopwatch is auto-saved at this length instead of growing forever.
  static const int maxStopwatchSeconds = 12 * 60 * 60;

  final SessionRepository _sessionRepository;
  final ActiveTimerDao _activeTimerDao;
  final SessionNotifier _notifier;
  final int Function() _nowMsProvider;

  final Rxn<ActiveTimerEntity> activeState = Rxn<ActiveTimerEntity>();
  final RxInt displaySeconds = 0.obs;
  final RxInt elapsedFocusSeconds = 0.obs;
  final RxDouble progress = 0.0.obs;
  final Rxn<StudySessionEntity> lastCompletedSession = Rxn<StudySessionEntity>();

  Timer? _uiTicker;
  bool _reconciling = false;

  bool get hasActiveSession => activeState.value != null;
  bool get isRunning =>
      activeState.value != null && !(activeState.value?.isPaused ?? true);
  bool get isPaused => activeState.value?.isPaused ?? false;

  /// Restores any persisted timer state after app relaunch or process recreation.
  Future<void> restoreOnLaunch() async {
    final row = await _activeTimerDao.getActiveState();
    if (row == null) {
      _clearReactiveState();
      return;
    }
    activeState.value = row.toEntity();
    await reconcile();
    if (hasActiveSession && isRunning) {
      _startUiTicker();
      // Alarms are lost after a force-stop; re-arm them on every launch.
      await _scheduleAlerts(activeState.value!);
    }
  }

  /// Starts a new Focus Timer, Stopwatch, or Pomodoro session (subject optional).
  Future<ActiveTimerEntity> startSession({
    int? subjectId,
    required TimerMode mode,
    int focusMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int totalCycles = 4,
    String? notes,
  }) async {
    final nowMs = _nowMsProvider();
    final safeFocus = math.max(1, focusMinutes);
    final safeShortBreak = math.max(1, shortBreakMinutes);
    final safeLongBreak = math.max(1, longBreakMinutes);
    final safeCycles = mode == TimerMode.pomodoro ? math.max(1, totalCycles) : 1;

    final plannedFocusSeconds = mode == TimerMode.stopwatch
        ? 0
        : (mode == TimerMode.focus ? safeFocus * 60 : safeCycles * safeFocus * 60);

    final sessionId = await _sessionRepository.createActiveSession(
      subjectId: subjectId,
      mode: mode,
      startedAtMs: nowMs,
      notes: notes,
    );

    final targetEndAtMs =
        mode == TimerMode.stopwatch ? null : nowMs + (safeFocus * 60 * 1000);

    final companion = ActiveTimerStatesCompanion(
      id: const drift.Value<int>(ActiveTimerDao.singleRowId),
      sessionId: drift.Value<int?>(sessionId),
      subjectId: drift.Value<int?>(subjectId),
      timerMode: drift.Value<String>(mode.key),
      phase: drift.Value<String>(TimerPhase.focusing.key),
      targetEndAt: drift.Value<int?>(targetEndAtMs),
      segmentStartedAt: drift.Value<int?>(nowMs),
      phasePausedRemainingSeconds: const drift.Value<int?>(null),
      accumulatedSeconds: const drift.Value<int>(0),
      plannedDurationSeconds: drift.Value<int>(plannedFocusSeconds),
      focusMinutes: drift.Value<int>(safeFocus),
      shortBreakMinutes: drift.Value<int>(safeShortBreak),
      longBreakMinutes: drift.Value<int>(safeLongBreak),
      totalCycles: drift.Value<int>(safeCycles),
      currentCycle: const drift.Value<int>(1),
      isPaused: const drift.Value<bool>(false),
      notes: drift.Value<String?>(notes),
      updatedAt: drift.Value<int>(nowMs),
    );

    await _activeTimerDao.saveActiveState(companion);
    final saved = await _activeTimerDao.getActiveState();
    final entity = saved!.toEntity();
    lastCompletedSession.value = null;
    activeState.value = entity;
    _updateComputedReadouts(entity, nowMs);
    _startUiTicker();
    await _scheduleAlerts(entity);
    return entity;
  }

  /// Pauses the active timer and persists accumulated elapsed/remaining state.
  Future<void> pause() async {
    final current = activeState.value;
    if (current == null || current.isPaused) {
      return;
    }
    final nowMs = _nowMsProvider();

    int newAccumulated = current.accumulatedSeconds;
    int? pausedRemaining;

    if (current.segmentStartedAtMs != null) {
      final deltaSec =
          math.max(0, (nowMs - current.segmentStartedAtMs!) ~/ 1000);
      if (current.timerMode == TimerMode.stopwatch ||
          current.phase == TimerPhase.focusing) {
        newAccumulated += deltaSec;
      }
    }

    if (current.timerMode != TimerMode.stopwatch && current.targetEndAtMs != null) {
      pausedRemaining =
          math.max(0, ((current.targetEndAtMs! - nowMs) / 1000).ceil());
    }

    if (current.sessionId != null) {
      await _sessionRepository.recordSessionEvent(
        sessionId: current.sessionId!,
        eventType: 'pause',
        startedAtMs: current.segmentStartedAtMs ?? nowMs,
        endedAtMs: nowMs,
        durationSeconds: newAccumulated - current.accumulatedSeconds,
      );
    }

    await _persistState(
      current,
      targetEndAtMs: null,
      segmentStartedAtMs: null,
      phasePausedRemainingSeconds: pausedRemaining,
      accumulatedSeconds: newAccumulated,
      isPaused: true,
      updatedAtMs: nowMs,
    );
    _stopUiTicker();
    await _notifier.cancelSessionAlerts();
  }

  /// Resumes a paused timer from persisted state using fresh UTC timestamps.
  Future<void> resume() async {
    final current = activeState.value;
    if (current == null || !current.isPaused) {
      return;
    }
    final nowMs = _nowMsProvider();

    int? newTargetEndAt;
    if (current.timerMode != TimerMode.stopwatch) {
      final remaining = current.phasePausedRemainingSeconds ??
          _phaseDurationSeconds(current, current.phase);
      newTargetEndAt = nowMs + (remaining * 1000);
    }

    if (current.sessionId != null) {
      await _sessionRepository.recordSessionEvent(
        sessionId: current.sessionId!,
        eventType: 'resume',
        startedAtMs: nowMs,
        endedAtMs: nowMs,
        durationSeconds: 0,
      );
    }

    await _persistState(
      current,
      targetEndAtMs: newTargetEndAt,
      segmentStartedAtMs: nowMs,
      phasePausedRemainingSeconds: null,
      accumulatedSeconds: current.accumulatedSeconds,
      isPaused: false,
      updatedAtMs: nowMs,
    );
    _startUiTicker();
    await _scheduleAlerts(activeState.value!);
  }

  /// Recomputes live display values and catches up any expired countdown phases.
  Future<void> reconcile([int? overrideNowMs]) async {
    if (_reconciling) {
      return;
    }
    _reconciling = true;
    try {
      var current = activeState.value;
      if (current == null) {
        final row = await _activeTimerDao.getActiveState();
        if (row == null) {
          _clearReactiveState();
          return;
        }
        current = row.toEntity();
        activeState.value = current;
      }

      final nowMs = overrideNowMs ?? _nowMsProvider();

      if (current.timerMode == TimerMode.stopwatch &&
          !current.isPaused &&
          _computeElapsedFocusSeconds(current, nowMs) >= maxStopwatchSeconds) {
        final remainingToCap =
            maxStopwatchSeconds - current.accumulatedSeconds;
        final capEndMs = (current.segmentStartedAtMs ?? nowMs) +
            (math.max(0, remainingToCap) * 1000);
        await _completeActiveSession(
          current,
          endedAtMs: math.min(capEndMs, nowMs),
          durationSeconds: maxStopwatchSeconds,
        );
        return;
      }

      if (current.isPaused || current.timerMode == TimerMode.stopwatch) {
        _updateComputedReadouts(current, nowMs);
        return;
      }

      var stateChanged = false;
      while (!current!.isPaused &&
          current.targetEndAtMs != null &&
          nowMs >= current.targetEndAtMs!) {
        final phaseEndMs = current.targetEndAtMs!;

        if (current.timerMode == TimerMode.focus) {
          final totalFocusSec = current.plannedDurationSeconds > 0
              ? current.plannedDurationSeconds
              : current.focusMinutes * 60;
          await _completeActiveSession(
            current,
            endedAtMs: phaseEndMs,
            durationSeconds: totalFocusSec,
          );
          return;
        }

        // Pomodoro phase transition
        if (current.phase == TimerPhase.longBreak) {
          // Long break ends the Pomodoro set: save focus time exactly once.
          await _completeActiveSession(
            current,
            endedAtMs: phaseEndMs,
            durationSeconds: current.accumulatedSeconds > 0
                ? current.accumulatedSeconds
                : current.plannedDurationSeconds,
          );
          return;
        }

        if (current.phase == TimerPhase.focusing) {
          final segmentStart = current.segmentStartedAtMs ?? phaseEndMs;
          final gained = math.max(0, (phaseEndMs - segmentStart) ~/ 1000);
          final nextAccumulated = math.min(
            current.plannedDurationSeconds,
            current.accumulatedSeconds + gained,
          );

          final isLastCycle = current.currentCycle >= current.totalCycles;
          final nextPhase =
              isLastCycle ? TimerPhase.longBreak : TimerPhase.shortBreak;
          final breakSec = _phaseDurationSeconds(current, nextPhase);
          current = ActiveTimerEntity(
            sessionId: current.sessionId,
            subjectId: current.subjectId,
            timerMode: current.timerMode,
            phase: nextPhase,
            targetEndAtMs: phaseEndMs + (breakSec * 1000),
            segmentStartedAtMs: phaseEndMs,
            phasePausedRemainingSeconds: null,
            accumulatedSeconds: nextAccumulated,
            plannedDurationSeconds: current.plannedDurationSeconds,
            focusMinutes: current.focusMinutes,
            shortBreakMinutes: current.shortBreakMinutes,
            longBreakMinutes: current.longBreakMinutes,
            totalCycles: current.totalCycles,
            currentCycle: current.currentCycle,
            isPaused: false,
            notes: current.notes,
            updatedAtMs: phaseEndMs,
          );
          stateChanged = true;
        } else {
          // Short break finished -> move to next cycle focusing
          final nextCycle = current.currentCycle + 1;
          final focusSec = current.focusMinutes * 60;
          current = ActiveTimerEntity(
            sessionId: current.sessionId,
            subjectId: current.subjectId,
            timerMode: current.timerMode,
            phase: TimerPhase.focusing,
            targetEndAtMs: phaseEndMs + (focusSec * 1000),
            segmentStartedAtMs: phaseEndMs,
            phasePausedRemainingSeconds: null,
            accumulatedSeconds: current.accumulatedSeconds,
            plannedDurationSeconds: current.plannedDurationSeconds,
            focusMinutes: current.focusMinutes,
            shortBreakMinutes: current.shortBreakMinutes,
            longBreakMinutes: current.longBreakMinutes,
            totalCycles: current.totalCycles,
            currentCycle: nextCycle,
            isPaused: false,
            notes: current.notes,
            updatedAtMs: phaseEndMs,
          );
          stateChanged = true;
        }
      }

      if (stateChanged) {
        await _saveEntityToDb(current);
        activeState.value = current;
      }

      _updateComputedReadouts(current, nowMs);
    } finally {
      _reconciling = false;
    }
  }

  /// Finishes the current session early and persists the focus duration studied.
  Future<StudySessionEntity?> finishEarly({String? notes}) async {
    final current = activeState.value;
    if (current == null || current.sessionId == null) {
      return null;
    }
    final nowMs = _nowMsProvider();
    final totalStudied = _computeElapsedFocusSeconds(current, nowMs);
    return _completeActiveSession(
      current,
      endedAtMs: nowMs,
      durationSeconds: totalStudied,
      notes: notes ?? current.notes,
    );
  }

  /// Cancels the active session without saving it as completed.
  Future<void> cancelSession() async {
    final current = activeState.value;
    _stopUiTicker();
    await _notifier.cancelSessionAlerts();
    if (current?.sessionId != null) {
      await _sessionRepository.cancelSession(
        sessionId: current!.sessionId!,
        cancelledAtMs: _nowMsProvider(),
      );
    } else {
      await _activeTimerDao.clearActiveState();
    }
    _clearReactiveState();
  }

  Future<StudySessionEntity> _completeActiveSession(
    ActiveTimerEntity current, {
    required int endedAtMs,
    required int durationSeconds,
    String? notes,
  }) async {
    _stopUiTicker();
    await _notifier.cancelSessionAlerts();
    final session = await _sessionRepository.completeSession(
      sessionId: current.sessionId!,
      endedAtMs: endedAtMs,
      durationSeconds: durationSeconds,
      notes: notes ?? current.notes,
    );
    lastCompletedSession.value = session;
    _clearReactiveState();
    return session;
  }

  Future<void> _persistState(
    ActiveTimerEntity base, {
    required int? targetEndAtMs,
    required int? segmentStartedAtMs,
    required int? phasePausedRemainingSeconds,
    required int accumulatedSeconds,
    required bool isPaused,
    required int updatedAtMs,
  }) async {
    final next = ActiveTimerEntity(
      sessionId: base.sessionId,
      subjectId: base.subjectId,
      timerMode: base.timerMode,
      phase: base.phase,
      targetEndAtMs: targetEndAtMs,
      segmentStartedAtMs: segmentStartedAtMs,
      phasePausedRemainingSeconds: phasePausedRemainingSeconds,
      accumulatedSeconds: accumulatedSeconds,
      plannedDurationSeconds: base.plannedDurationSeconds,
      focusMinutes: base.focusMinutes,
      shortBreakMinutes: base.shortBreakMinutes,
      longBreakMinutes: base.longBreakMinutes,
      totalCycles: base.totalCycles,
      currentCycle: base.currentCycle,
      isPaused: isPaused,
      notes: base.notes,
      updatedAtMs: updatedAtMs,
    );
    await _saveEntityToDb(next);
    activeState.value = next;
    _updateComputedReadouts(next, updatedAtMs);
  }

  Future<void> _saveEntityToDb(ActiveTimerEntity entity) {
    return _activeTimerDao.saveActiveState(
      ActiveTimerStatesCompanion(
        id: const drift.Value<int>(ActiveTimerDao.singleRowId),
        sessionId: drift.Value<int?>(entity.sessionId),
        subjectId: drift.Value<int?>(entity.subjectId),
        timerMode: drift.Value<String>(entity.timerMode.key),
        phase: drift.Value<String>(entity.phase.key),
        targetEndAt: drift.Value<int?>(entity.targetEndAtMs),
        segmentStartedAt: drift.Value<int?>(entity.segmentStartedAtMs),
        phasePausedRemainingSeconds:
            drift.Value<int?>(entity.phasePausedRemainingSeconds),
        accumulatedSeconds: drift.Value<int>(entity.accumulatedSeconds),
        plannedDurationSeconds: drift.Value<int>(entity.plannedDurationSeconds),
        focusMinutes: drift.Value<int>(entity.focusMinutes),
        shortBreakMinutes: drift.Value<int>(entity.shortBreakMinutes),
        longBreakMinutes: drift.Value<int>(entity.longBreakMinutes),
        totalCycles: drift.Value<int>(entity.totalCycles),
        currentCycle: drift.Value<int>(entity.currentCycle),
        isPaused: drift.Value<bool>(entity.isPaused),
        notes: drift.Value<String?>(entity.notes),
        updatedAt: drift.Value<int>(entity.updatedAtMs),
      ),
    );
  }

  /// Re-arms alerts for the running session (e.g. after alerts are re-enabled).
  Future<void> rescheduleAlerts() async {
    final current = activeState.value;
    if (current != null && !current.isPaused) {
      await _scheduleAlerts(current);
    }
  }

  Future<void> _scheduleAlerts(ActiveTimerEntity entity) async {
    try {
      await _notifier.scheduleSessionAlerts(buildAlertTimeline(entity));
    } catch (_) {
      // Alerts are best-effort; the timestamp-based timer stays correct.
    }
  }

  /// Every upcoming phase-end alert for a running [entity], derived purely
  /// from persisted timestamps (so it can be rebuilt after process death).
  List<ScheduledAlert> buildAlertTimeline(ActiveTimerEntity entity) {
    if (entity.isPaused) {
      return const <ScheduledAlert>[];
    }

    if (entity.timerMode == TimerMode.stopwatch) {
      final start = entity.segmentStartedAtMs;
      if (start == null) {
        return const <ScheduledAlert>[];
      }
      final remaining = maxStopwatchSeconds - entity.accumulatedSeconds;
      return <ScheduledAlert>[
        ScheduledAlert(
          atMs: start + (math.max(0, remaining) * 1000),
          title: 'Stopwatch saved',
          body: 'Your stopwatch reached 12 hours, so the session was saved.',
        ),
      ];
    }

    final firstEndMs = entity.targetEndAtMs;
    if (firstEndMs == null) {
      return const <ScheduledAlert>[];
    }
    var endMs = firstEndMs;

    if (entity.timerMode == TimerMode.focus) {
      return <ScheduledAlert>[
        ScheduledAlert(
          atMs: endMs,
          title: 'Focus session complete',
          body: 'Great work! Open ParhaiMate to see your session summary.',
        ),
      ];
    }

    final alerts = <ScheduledAlert>[];
    var phase = entity.phase;
    var cycle = entity.currentCycle;
    while (true) {
      switch (phase) {
        case TimerPhase.focusing:
          final isLast = cycle >= entity.totalCycles;
          alerts.add(
            ScheduledAlert(
              atMs: endMs,
              title: isLast ? 'Pomodoro set done' : 'Focus cycle $cycle done',
              body: isLast
                  ? 'Enjoy a ${entity.longBreakMinutes} min long break.'
                  : 'Take a ${entity.shortBreakMinutes} min break.',
            ),
          );
          phase = isLast ? TimerPhase.longBreak : TimerPhase.shortBreak;
          endMs = endMs + (_phaseDurationSeconds(entity, phase) * 1000);
        case TimerPhase.shortBreak:
          cycle += 1;
          alerts.add(
            ScheduledAlert(
              atMs: endMs,
              title: 'Break over',
              body: 'Cycle $cycle of ${entity.totalCycles} is starting. Back to focus!',
            ),
          );
          phase = TimerPhase.focusing;
          endMs = endMs + (entity.focusMinutes * 60 * 1000);
        case TimerPhase.longBreak:
          alerts.add(
            ScheduledAlert(
              atMs: endMs,
              title: 'Study session complete',
              body: 'Open ParhaiMate to see your session summary.',
            ),
          );
          return alerts;
      }
    }
  }

  int _phaseDurationSeconds(ActiveTimerEntity entity, TimerPhase phase) {
    switch (phase) {
      case TimerPhase.focusing:
        return entity.focusMinutes * 60;
      case TimerPhase.shortBreak:
        return entity.shortBreakMinutes * 60;
      case TimerPhase.longBreak:
        return entity.longBreakMinutes * 60;
    }
  }

  int _computeElapsedFocusSeconds(ActiveTimerEntity entity, int nowMs) {
    var total = entity.accumulatedSeconds;
    if (!entity.isPaused && entity.segmentStartedAtMs != null) {
      if (entity.timerMode == TimerMode.stopwatch ||
          entity.phase == TimerPhase.focusing) {
        total += math.max(0, (nowMs - entity.segmentStartedAtMs!) ~/ 1000);
      }
    }
    return total;
  }

  void _updateComputedReadouts(ActiveTimerEntity entity, int nowMs) {
    final focusSec = _computeElapsedFocusSeconds(entity, nowMs);
    elapsedFocusSeconds.value = focusSec;

    if (entity.timerMode == TimerMode.stopwatch) {
      displaySeconds.value = focusSec;
      // Smooth repeating minute arc on stopwatch ring
      progress.value = (focusSec % 3600) / 3600.0;
      return;
    }

    final phaseTotal = _phaseDurationSeconds(entity, entity.phase);
    final remaining = entity.isPaused
        ? (entity.phasePausedRemainingSeconds ?? phaseTotal)
        : (entity.targetEndAtMs == null
            ? 0
            : math.max(0, ((entity.targetEndAtMs! - nowMs) / 1000).ceil()));

    displaySeconds.value = remaining;
    if (phaseTotal <= 0) {
      progress.value = 0;
    } else {
      progress.value = ((phaseTotal - remaining) / phaseTotal).clamp(0.0, 1.0);
    }
  }

  void _startUiTicker() {
    _stopUiTicker();
    _uiTicker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => unawaited(reconcile()),
    );
  }

  void _stopUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = null;
  }

  void _clearReactiveState() {
    activeState.value = null;
    displaySeconds.value = 0;
    elapsedFocusSeconds.value = 0;
    progress.value = 0.0;
  }

  @override
  void onClose() {
    _stopUiTicker();
    super.onClose();
  }
}
