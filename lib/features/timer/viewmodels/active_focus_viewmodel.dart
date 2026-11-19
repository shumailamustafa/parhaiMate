import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for distraction-free Active Focus screen (06 Active Focus.png).
class ActiveFocusViewModel extends GetxController {
  ActiveFocusViewModel({
    required this.timerEngine,
    required SubjectRepository subjectRepository,
    required SessionRepository sessionRepository,
  })  : _subjectRepository = subjectRepository,
        _sessionRepository = sessionRepository;

  final TimerEngineService timerEngine;
  final SubjectRepository _subjectRepository;
  final SessionRepository _sessionRepository;

  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  final RxnInt startedAtMs = RxnInt();
  final RxBool isSubmitting = false.obs;

  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  Worker? _completionWorker;
  Worker? _activeWorker;
  bool _handlingManualAction = false;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _subjectsSub = _subjectRepository.watchSubjects().listen(subjects.assignAll);
    unawaited(_loadSessionStartTimestamp(timerEngine.activeState.value));

    _activeWorker = ever<ActiveTimerEntity?>(timerEngine.activeState, (state) {
      unawaited(_loadSessionStartTimestamp(state));
    });

    _completionWorker = ever<StudySessionEntity?>(
      timerEngine.lastCompletedSession,
      (session) {
        if (_disposed || _handlingManualAction || session == null) {
          return;
        }
        if (!timerEngine.hasActiveSession) {
          unawaited(
            Get.offNamed<void>(
              AppRoutes.sessionSummary,
              arguments: session.id,
            ),
          );
        }
      },
    );
  }

  Future<void> _loadSessionStartTimestamp(ActiveTimerEntity? state) async {
    final sessionId = state?.sessionId;
    if (sessionId == null) {
      return;
    }
    final session = await _sessionRepository.getById(sessionId);
    if (!_disposed && session != null) {
      startedAtMs.value = session.startedAtMs;
    }
  }

  ActiveTimerEntity? get active => timerEngine.activeState.value;

  SubjectEntity? get currentSubject {
    final id = active?.subjectId;
    if (id == null) {
      return null;
    }
    for (final s in subjects) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }

  String get subjectName => currentSubject?.name ?? 'General Study';

  SubjectIdentifier get subjectIdentifier =>
      currentSubject?.identifier ?? SubjectIdentifier.circle;

  String get modeLabel => active?.timerMode.label ?? 'Focus Timer';

  String get timerClockText =>
      DateTimeUtils.formatTimerClock(timerEngine.displaySeconds.value);

  String get ringCaption {
    final current = active;
    if (current == null) {
      return 'remaining';
    }
    if (current.timerMode == TimerMode.stopwatch) {
      return 'elapsed';
    }
    switch (current.phase) {
      case TimerPhase.focusing:
        return 'remaining';
      case TimerPhase.shortBreak:
        return 'Short break';
      case TimerPhase.longBreak:
        return 'Long break';
    }
  }

  int get elapsedFocusMinutes => timerEngine.elapsedFocusSeconds.value ~/ 60;

  int get totalPlannedFocusMinutes {
    final current = active;
    if (current == null) {
      return 0;
    }
    if (current.timerMode == TimerMode.pomodoro) {
      return current.totalCycles * current.focusMinutes;
    }
    return current.focusMinutes;
  }

  String get startedAtLabel {
    final ms = startedAtMs.value ?? active?.updatedAtMs;
    if (ms == null) {
      return '';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return 'Started ${DateTimeUtils.formatClockTime(dt)}';
  }

  String get statusLabel {
    final current = active;
    if (current == null) {
      return '';
    }
    if (current.isPaused) {
      return 'Paused';
    }
    switch (current.phase) {
      case TimerPhase.focusing:
        return 'Focusing';
      case TimerPhase.shortBreak:
        return 'On a short break';
      case TimerPhase.longBreak:
        return 'On a long break';
    }
  }

  String get studiedDurationForDialog =>
      DateTimeUtils.formatSecondsAsMinutesLabel(
        timerEngine.elapsedFocusSeconds.value,
      );

  Future<void> togglePauseResume() async {
    if (timerEngine.isPaused) {
      await timerEngine.resume();
    } else {
      await timerEngine.pause();
    }
  }

  Future<void> finishSessionEarly() async {
    if (isSubmitting.value) {
      return;
    }
    _handlingManualAction = true;
    isSubmitting.value = true;
    try {
      final session = await timerEngine.finishEarly();
      if (session != null) {
        unawaited(
          Get.offNamed<void>(
            AppRoutes.sessionSummary,
            arguments: session.id,
          ),
        );
      } else {
        unawaited(Get.offAllNamed<void>(AppRoutes.home));
      }
    } finally {
      _handlingManualAction = false;
      if (!_disposed) {
        isSubmitting.value = false;
      }
    }
  }

  Future<void> cancelSession() async {
    if (isSubmitting.value) {
      return;
    }
    _handlingManualAction = true;
    isSubmitting.value = true;
    try {
      await timerEngine.cancelSession();
      unawaited(Get.offAllNamed<void>(AppRoutes.home));
    } finally {
      _handlingManualAction = false;
      if (!_disposed) {
        isSubmitting.value = false;
      }
    }
  }

  void minimizeToHome() {
    unawaited(Get.offAllNamed<void>(AppRoutes.home));
  }

  @override
  void onClose() {
    _disposed = true;
    _completionWorker?.dispose();
    _activeWorker?.dispose();
    unawaited(_subjectsSub?.cancel());
    super.onClose();
  }
}
