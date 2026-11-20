import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:parhaimate/app/app.dart';
import 'package:parhaimate/app/bindings/initial_binding.dart';
import 'package:parhaimate/app/lifecycle/app_lifecycle_handler.dart';
import 'package:parhaimate/app/routes/app_pages.dart';
import 'package:parhaimate/app/routes/app_routes.dart';
import 'package:parhaimate/core/services/timer_engine_service.dart';
import 'package:parhaimate/core/theme/app_theme.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';
import 'package:parhaimate/features/achievements/viewmodels/achievements_viewmodel.dart';
import 'package:parhaimate/features/achievements/views/achievements_view.dart';
import 'package:parhaimate/features/goals/viewmodels/goals_viewmodel.dart';
import 'package:parhaimate/features/goals/views/goals_streaks_view.dart';
import 'package:parhaimate/features/statistics/viewmodels/session_history_viewmodel.dart';
import 'package:parhaimate/features/statistics/viewmodels/statistics_viewmodel.dart';
import 'package:parhaimate/features/statistics/views/session_history_view.dart';
import 'package:parhaimate/features/statistics/views/statistics_view.dart';
import 'package:parhaimate/shared/enums/subject_visuals.dart';

Future<void> _disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  if (Get.isRegistered<AppLifecycleHandler>()) {
    Get.find<AppLifecycleHandler>().detach();
  }
  if (Get.isRegistered<TimerEngineService>()) {
    Get.find<TimerEngineService>().onClose();
  }
  Get.reset();
  // Allow Drift's zero-duration StreamQueryStore cleanup timer to run cleanly.
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late AppDatabase db;

  setUp(() {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    if (Get.isRegistered<AppLifecycleHandler>()) {
      Get.find<AppLifecycleHandler>().detach();
    }
    if (Get.isRegistered<TimerEngineService>()) {
      Get.find<TimerEngineService>().onClose();
    }
    Get.reset();
    await db.close();
  });

  group('Section 5.6 Progress — Statistics, History, Goals & Achievements', () {
    testWidgets(
        'renders No study activity yet on empty Statistics and switches Week/Month/Year dynamically when data exists',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.home,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('No study activity yet'), findsOneWidget);
      expect(find.text('Goals & Streaks'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Session History'), findsOneWidget);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'switches Week/Month/Year Statistics dynamically when study sessions exist',
        (tester) async {
      final fixedNow = DateTime(2026, 5, 12, 15, 0);
      InitialBinding(database: db).dependencies();

      final subjectRepo = Get.find<SubjectRepository>();
      final sessionRepo = Get.find<SessionRepository>();
      final mathId = await subjectRepo.createSubject(
        name: 'Mathematics',
        identifier: SubjectIdentifier.circle,
        iconKey: SubjectIconKey.sigma,
        targetMinutes: 300,
      );
      final progId = await subjectRepo.createSubject(
        name: 'Programming',
        identifier: SubjectIdentifier.square,
        iconKey: SubjectIconKey.code,
        targetMinutes: 360,
      );

      // Week session (12 May = 90m)
      final mayStart = DateTime(2026, 5, 12, 9, 0).toUtc().millisecondsSinceEpoch;
      final s1 = await sessionRepo.createActiveSession(
        subjectId: mathId,
        mode: TimerMode.pomodoro,
        startedAtMs: mayStart,
      );
      await sessionRepo.completeSession(
        sessionId: s1,
        endedAtMs: mayStart + 90 * 60 * 1000,
        durationSeconds: 90 * 60,
      );

      // Earlier month session (1 May = 60m)
      final mayEarly = DateTime(2026, 5, 1, 9, 0).toUtc().millisecondsSinceEpoch;
      final s2 = await sessionRepo.createActiveSession(
        subjectId: progId,
        mode: TimerMode.focus,
        startedAtMs: mayEarly,
      );
      await sessionRepo.completeSession(
        sessionId: s2,
        endedAtMs: mayEarly + 60 * 60 * 1000,
        durationSeconds: 60 * 60,
      );

      // Earlier year session (15 April = 45m)
      final aprilStart =
          DateTime(2026, 4, 15, 9, 0).toUtc().millisecondsSinceEpoch;
      final s3 = await sessionRepo.createActiveSession(
        subjectId: mathId,
        mode: TimerMode.stopwatch,
        startedAtMs: aprilStart,
      );
      await sessionRepo.completeSession(
        sessionId: s3,
        endedAtMs: aprilStart + 45 * 60 * 1000,
        durationSeconds: 45 * 60,
      );

      Get.put<StatisticsViewModel>(
        StatisticsViewModel(
          sessionRepository: sessionRepo,
          subjectRepository: subjectRepo,
          goalStreakRepository: Get.find<GoalStreakRepository>(),
          achievementRepository: Get.find<AchievementRepository>(),
          nowProvider: () => fixedNow,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const Scaffold(body: StatisticsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly Study Time'), findsOneWidget);
      expect(find.text('1h 30m'), findsWidgets);
      expect(find.text('Subject Distribution'), findsOneWidget);
      expect(find.text('Daily Study Activity'), findsOneWidget);
      expect(find.text('Most Studied Subject'), findsOneWidget);

      // Switch to Month -> updates total (2h 30m) & title dynamically!
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Study Time'), findsOneWidget);
      expect(find.text('2h 30m'), findsWidgets);

      // Switch to Year -> updates total (3h 15m) & title dynamically!
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(find.text('Yearly Study Time'), findsOneWidget);
      expect(find.text('3h 15m'), findsWidgets);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'Session History filters by subject chips & toggles sort order, Goals & Streaks edits & persists targets, and Achievements opens detail sheets',
        (tester) async {
      final fixedNow = DateTime(2026, 5, 12, 15, 0);
      final binding = InitialBinding(database: db)..dependencies();
      expect(binding, isNotNull);

      final subjectRepo = Get.find<SubjectRepository>();
      final sessionRepo = Get.find<SessionRepository>();
      final goalRepo = Get.find<GoalStreakRepository>();
      final achievementRepo = Get.find<AchievementRepository>();

      final mathId = await subjectRepo.createSubject(
        name: 'Mathematics',
        identifier: SubjectIdentifier.circle,
        iconKey: SubjectIconKey.sigma,
        targetMinutes: 300,
      );
      final dbId = await subjectRepo.createSubject(
        name: 'Database Systems',
        identifier: SubjectIdentifier.triangle,
        iconKey: SubjectIconKey.database,
        targetMinutes: 240,
      );

      // 150m Mathematics + 60m Database Systems on fixedNow -> First Session & Focus Starter unlock!
      final start1 = DateTime(2026, 5, 12, 8, 0).toUtc().millisecondsSinceEpoch;
      final id1 = await sessionRepo.createActiveSession(
        subjectId: mathId,
        mode: TimerMode.pomodoro,
        startedAtMs: start1,
      );
      await sessionRepo.completeSession(
        sessionId: id1,
        endedAtMs: start1 + 150 * 60 * 1000,
        durationSeconds: 150 * 60,
      );

      final start2 = DateTime(2026, 5, 11, 9, 0).toUtc().millisecondsSinceEpoch;
      final id2 = await sessionRepo.createActiveSession(
        subjectId: dbId,
        mode: TimerMode.stopwatch,
        startedAtMs: start2,
      );
      await sessionRepo.completeSession(
        sessionId: id2,
        endedAtMs: start2 + 60 * 60 * 1000,
        durationSeconds: 60 * 60,
      );

      // 1. Test Session History filter & sort toggle
      Get.put<SessionHistoryViewModel>(
        SessionHistoryViewModel(
          sessionRepository: sessionRepo,
          subjectRepository: subjectRepo,
          nowProvider: () => fixedNow,
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const SessionHistoryView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Newest first'), findsOneWidget);
      expect(find.text('Mathematics'), findsWidgets);
      expect(find.text('Database Systems'), findsWidgets);

      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Oldest first'), findsOneWidget);

      await tester.tap(find.text('Database Systems').first);
      await tester.pumpAndSettle();
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Today'), findsNothing);

      // 2. Test Goals & Streaks live steppers + Save Changes button state
      Get.put<GoalsViewModel>(
        GoalsViewModel(
          goalStreakRepository: goalRepo,
          sessionRepository: sessionRepo,
          nowProvider: () => fixedNow,
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const GoalsStreaksView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('63%'), findsOneWidget); // 150 / 240 min
      expect(find.text('240 min'), findsOneWidget);

      // Increment Daily study goal 240 -> 270 min dynamically updates ring % (63% -> 56%)!
      await tester.ensureVisible(find.byIcon(Icons.add_rounded).first);
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('270 min'), findsOneWidget);
      expect(find.text('4h 30m a day'), findsOneWidget);

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(await goalRepo.getDailyGoalMinutes(dateKey: '2026-05-12'), 270);

      // 3. Test Achievements grid & unlocked/locked detail bottom sheets
      Get.put<AchievementsViewModel>(
        AchievementsViewModel(achievementRepository: achievementRepo),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const AchievementsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 of 6 unlocked'), findsOneWidget);
      expect(find.text('First Session'), findsOneWidget);
      expect(find.text('Time Master'), findsOneWidget);

      // Tap unlocked First Session card -> sheet shows Unlocked & Done
      await tester.tap(find.text('First Session'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Tap locked Time Master card -> sheet shows Start Studying & Done
      await tester.ensureVisible(find.text('Time Master'));
      await tester.tap(find.text('Time Master'));
      await tester.pumpAndSettle();
      expect(find.text('Start Studying'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await _disposeWidgetTree(tester);
    });
  });
}
