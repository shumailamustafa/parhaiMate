import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parhaimate/core/services/session_notifier.dart';
import 'package:parhaimate/core/services/timer_engine_service.dart';
import 'package:parhaimate/core/utils/date_time_utils.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/data/repositories/drift_repositories.dart';
import 'package:parhaimate/domain/enums/domain_enums.dart';
import 'package:parhaimate/features/settings/viewmodels/settings_viewmodel.dart';

class _RecordingNotifier implements SessionNotifier {
  List<ScheduledAlert> scheduled = <ScheduledAlert>[];
  int cancelCount = 0;

  @override
  Future<void> scheduleSessionAlerts(List<ScheduledAlert> alerts) async {
    scheduled = alerts;
  }

  @override
  Future<void> cancelSessionAlerts() async {
    cancelCount += 1;
  }
}

void main() {
  late AppDatabase db;
  late int fakeNowMs;
  late DateTime fakeNowLocal;
  late DriftSubjectRepository subjectRepo;
  late DriftGoalStreakRepository goalStreakRepo;
  late DriftAchievementRepository achievementRepo;
  late DriftSessionRepository sessionRepo;
  late TimerEngineService timerEngine;

  setUp(() async {
    fakeNowLocal = DateTime(2026, 5, 12, 15, 20);
    fakeNowMs = fakeNowLocal.toUtc().millisecondsSinceEpoch;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    subjectRepo = DriftSubjectRepository(db);
    goalStreakRepo = DriftGoalStreakRepository(
      db,
      nowProvider: () => fakeNowLocal,
    );
    achievementRepo = DriftAchievementRepository(
      db,
      goalStreakRepo,
      nowProvider: () => fakeNowLocal,
    );
    sessionRepo = DriftSessionRepository(db, achievementRepo);
    timerEngine = TimerEngineService(
      sessionRepository: sessionRepo,
      activeTimerDao: db.activeTimerDao,
      nowMsProvider: () => fakeNowMs,
    );
  });

  tearDown(() async {
    timerEngine.onClose();
    await db.close();
  });

  group('Stage 4 Timer Engine & Domain Logic', () {
    test('Focus countdown calculates from targetEndAt and completes once',
        () async {
      // Start without selecting a subject (subjectId is optional).
      final active = await timerEngine.startSession(
        mode: TimerMode.focus,
        focusMinutes: 25,
        notes: 'Unassigned deep reading',
      );
      expect(active.subjectId, isNull);
      expect(timerEngine.displaySeconds.value, 1500);

      // Advance clock by 12 minutes 34 seconds -> remaining should be 12:26 (746s)
      fakeNowMs += (12 * 60 + 34) * 1000;
      await timerEngine.reconcile();
      expect(timerEngine.displaySeconds.value, 746);
      expect(timerEngine.elapsedFocusSeconds.value, 754);

      // Advance past end of 25-minute timer -> completes automatically
      fakeNowMs += 15 * 60 * 1000;
      await timerEngine.reconcile();
      expect(timerEngine.hasActiveSession, isFalse);
      final completed = timerEngine.lastCompletedSession.value;
      expect(completed, isNotNull);
      expect(completed!.subjectId, isNull);
      expect(completed.durationSeconds, 1500);
      expect(completed.status, SessionStatus.completed);

      // Calling completeSession again on the same ID is idempotent.
      final secondCall = await sessionRepo.completeSession(
        sessionId: completed.id,
        endedAtMs: fakeNowMs,
        durationSeconds: 9999,
      );
      expect(secondCall.durationSeconds, 1500);
      final allCompleted = await sessionRepo.getCompletedSessions();
      expect(allCompleted.length, 1);

      // First Session achievement unlocked
      final achievements = await achievementRepo.getAchievements();
      final firstSession =
          achievements.firstWhere((a) => a.code == 'first_session');
      expect(firstSession.isUnlocked, isTrue);
    });

    test('Stopwatch tracks elapsed segments across pause and resume', () async {
      final subjectId = await subjectRepo.createSubject(
        name: 'Database Systems',
        identifier: SubjectIdentifier.triangle,
        iconKey: SubjectIconKey.database,
        targetMinutes: 240,
      );

      await timerEngine.startSession(
        subjectId: subjectId,
        mode: TimerMode.stopwatch,
      );

      fakeNowMs += 20 * 60 * 1000; // +20m
      await timerEngine.reconcile();
      expect(timerEngine.displaySeconds.value, 1200);

      await timerEngine.pause();
      expect(timerEngine.isPaused, isTrue);

      // Passing time while paused must NOT count toward elapsed duration.
      fakeNowMs += 10 * 60 * 1000;
      await timerEngine.reconcile();
      expect(timerEngine.displaySeconds.value, 1200);

      await timerEngine.resume();
      fakeNowMs += 35 * 60 * 1000; // +35m
      await timerEngine.reconcile();
      expect(timerEngine.displaySeconds.value, 55 * 60);

      final saved = await timerEngine.finishEarly();
      expect(saved, isNotNull);
      expect(saved!.durationSeconds, 55 * 60);
      expect(saved.subjectId, subjectId);
    });

    test('Pomodoro transitions focus -> short break -> next cycle -> long break & recovers on relaunch',
        () async {
      await timerEngine.startSession(
        mode: TimerMode.pomodoro,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        totalCycles: 4,
      );

      // Simulate app killed and reopened 27 minutes later (inside Cycle 1 short break)
      fakeNowMs += 27 * 60 * 1000;

      final restoredEngine = TimerEngineService(
        sessionRepository: sessionRepo,
        activeTimerDao: db.activeTimerDao,
        nowMsProvider: () => fakeNowMs,
      );
      await restoredEngine.restoreOnLaunch();

      expect(restoredEngine.hasActiveSession, isTrue);
      expect(restoredEngine.activeState.value!.phase, TimerPhase.shortBreak);
      expect(restoredEngine.activeState.value!.currentCycle, 1);
      expect(restoredEngine.displaySeconds.value, 3 * 60);

      // Pause during short break, wait 5 min, resume, then advance to end of all 4 cycles
      await restoredEngine.pause();
      fakeNowMs += 5 * 60 * 1000;
      await restoredEngine.reconcile();
      expect(restoredEngine.displaySeconds.value, 3 * 60);

      await restoredEngine.resume();
      // Remaining: 3m break + 3*(25m focus) + 2*(5m break) = 88m
      fakeNowMs += 89 * 60 * 1000;
      await restoredEngine.reconcile();

      // After the 4th focus cycle the set moves into the 15m long break.
      expect(restoredEngine.hasActiveSession, isTrue);
      expect(restoredEngine.activeState.value!.phase, TimerPhase.longBreak);
      expect(restoredEngine.activeState.value!.currentCycle, 4);
      expect(restoredEngine.displaySeconds.value, 14 * 60);

      // Long break ends -> session completes with focus time only.
      fakeNowMs += 15 * 60 * 1000;
      await restoredEngine.reconcile();

      expect(restoredEngine.hasActiveSession, isFalse);
      expect(restoredEngine.lastCompletedSession.value, isNotNull);
      expect(restoredEngine.lastCompletedSession.value!.durationSeconds, 100 * 60);

      // Focus Starter (1 hour) achievement should also be unlocked now!
      final achievements = await achievementRepo.getAchievements();
      final focusStarter =
          achievements.firstWhere((a) => a.code == 'focus_starter');
      expect(focusStarter.isUnlocked, isTrue);

      restoredEngine.onClose();
    });

    test('forgotten stopwatch is auto-saved at the 12 hour cap', () async {
      await timerEngine.startSession(mode: TimerMode.stopwatch);

      fakeNowMs += 30 * 60 * 60 * 1000; // left running for 30 hours
      await timerEngine.reconcile();

      expect(timerEngine.hasActiveSession, isFalse);
      final saved = timerEngine.lastCompletedSession.value!;
      expect(saved.durationSeconds, TimerEngineService.maxStopwatchSeconds);
      expect(
        saved.endedAtMs! - saved.startedAtMs,
        TimerEngineService.maxStopwatchSeconds * 1000,
      );
    });

    test('alert timeline covers every Pomodoro phase and ends after the long break',
        () async {
      final active = await timerEngine.startSession(
        mode: TimerMode.pomodoro,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        totalCycles: 2,
      );
      final alerts = timerEngine.buildAlertTimeline(active);
      final minutes =
          alerts.map((a) => (a.atMs - fakeNowMs) ~/ 60000).toList();
      // focus1 end, break end, focus2 end (long break starts), long break end
      expect(minutes, <int>[25, 30, 55, 70]);
      expect(alerts.last.title, 'Study session complete');

      await timerEngine.pause();
      expect(
        timerEngine.buildAlertTimeline(timerEngine.activeState.value!),
        isEmpty,
      );
    });

    test('completion while backgrounded keeps the pending alert; foreground cancels it',
        () async {
      final notifier = _RecordingNotifier();
      final engine = TimerEngineService(
        sessionRepository: sessionRepo,
        activeTimerDao: db.activeTimerDao,
        nowMsProvider: () => fakeNowMs,
        notifier: notifier,
      );

      // Background: the session ends while the user is away.
      await engine.startSession(mode: TimerMode.focus, focusMinutes: 25);
      expect(notifier.scheduled.single.title, 'Focus session complete');
      engine.onAppBackgrounded();
      notifier.cancelCount = 0;
      fakeNowMs += 26 * 60 * 1000;
      await engine.reconcile();
      expect(engine.hasActiveSession, isFalse);
      expect(notifier.cancelCount, 0,
          reason: 'the scheduled completion alert must still be delivered');

      // Foreground: the user sees the summary, so pending alerts are dropped.
      await engine.onAppForegrounded();
      await engine.startSession(mode: TimerMode.focus, focusMinutes: 25);
      notifier.cancelCount = 0;
      fakeNowMs += 26 * 60 * 1000;
      await engine.reconcile();
      expect(engine.hasActiveSession, isFalse);
      expect(notifier.cancelCount, 1);

      engine.onClose();
    });

    test('Clear Study History during a live session stops the timer safely',
        () async {
      final settingsVm = SettingsViewModel(
        settingsRepository: DriftSettingsRepository(db),
        goalStreakRepository: goalStreakRepo,
        presetRepository: DriftPresetRepository(db),
        sessionRepository: sessionRepo,
        subjectRepository: subjectRepo,
        timerEngine: timerEngine,
      );

      await timerEngine.startSession(mode: TimerMode.focus, focusMinutes: 25);
      await settingsVm.clearStudyHistory();

      expect(timerEngine.hasActiveSession, isFalse);
      // Previously this threw StateError('Session not found') when the
      // still-running timer reached its end.
      fakeNowMs += 30 * 60 * 1000;
      await timerEngine.reconcile();
      expect(await sessionRepo.getCompletedSessions(), isEmpty);
      expect(await db.activeTimerDao.getActiveState(), isNull);
    });

    test('calculates current and longest streaks across days', () async {
      final days = <DateTime>[
        DateTime(2026, 5, 5, 10),
        DateTime(2026, 5, 6, 10),
        DateTime(2026, 5, 7, 10),
        // missed May 8
        DateTime(2026, 5, 11, 10),
        DateTime(2026, 5, 12, 10), // today
      ];
      for (final d in days) {
        final key = DateTimeUtils.toDateKey(d);
        await db.goalStreakDao.addStudyMinutesForDate(
          dateKey: key,
          addedMinutes: 45,
        );
      }

      final summary = await goalStreakRepo.getStreakSummary();
      expect(summary.longestStreak, 3);
      expect(summary.currentStreak, 2);
    });
  });
}
