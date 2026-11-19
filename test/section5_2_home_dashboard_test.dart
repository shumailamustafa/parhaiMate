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
import 'package:parhaimate/core/utils/date_time_utils.dart';
import 'package:parhaimate/core/widgets/pm_inputs.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/domain/enums/domain_enums.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';
import 'package:parhaimate/features/home/viewmodels/home_viewmodel.dart';
import 'package:parhaimate/features/home/viewmodels/main_shell_viewmodel.dart';
import 'package:parhaimate/features/home/views/main_shell_view.dart';
import 'package:parhaimate/features/subjects/viewmodels/subjects_viewmodel.dart';
import 'package:parhaimate/features/timer/viewmodels/study_timer_viewmodel.dart';

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
  // Allow Drift's zero-duration StreamQueryStore cleanup timer to run inside FakeAsync.
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

  group('Section 5.2 Main Shell & Home Dashboard', () {
    testWidgets('renders empty Home Dashboard when no tasks or sessions exist',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.home,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready to make today productive?'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0m'), findsWidgets);
      expect(find.text('of 4h target'), findsOneWidget);
      expect(find.text('Start Studying'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Plan Study'), findsWidgets);
      expect(find.text('Nothing planned'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);
      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'renders populated Home Dashboard, toggles schedule task, and switches tabs',
        (tester) async {
      final fixedNow = DateTime(2026, 5, 12, 14, 15);
      final binding = InitialBinding(database: db);
      binding.dependencies();

      final subjectRepo = Get.find<SubjectRepository>();
      final sessionRepo = Get.find<SessionRepository>();
      final plannerRepo = Get.find<PlannerRepository>();
      final goalRepo = Get.find<GoalStreakRepository>();

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

      // Seed 150 minutes (2h 30m) studied on fixedNow (63% of 4h target)
      final s1Start = DateTime(2026, 5, 12, 7, 35).toUtc().millisecondsSinceEpoch;
      final s1Id = await sessionRepo.createActiveSession(
        subjectId: mathId,
        mode: TimerMode.pomodoro,
        startedAtMs: s1Start,
      );
      await sessionRepo.completeSession(
        sessionId: s1Id,
        endedAtMs: s1Start + 50 * 60 * 1000,
        durationSeconds: 50 * 60,
      );

      final s2Start =
          DateTime(2026, 5, 12, 13, 10).toUtc().millisecondsSinceEpoch;
      final s2Id = await sessionRepo.createActiveSession(
        subjectId: dbId,
        mode: TimerMode.stopwatch,
        startedAtMs: s2Start,
      );
      await sessionRepo.completeSession(
        sessionId: s2Id,
        endedAtMs: s2Start + 100 * 60 * 1000,
        durationSeconds: 100 * 60,
      );

      await plannerRepo.createTask(
        subjectId: mathId,
        title: 'Revise integration by parts',
        scheduledDate: DateTimeUtils.toDateKey(fixedNow),
        scheduledTime: '16:00',
        targetMinutes: 45,
      );

      Get.put<MainShellViewModel>(
        MainShellViewModel(timerEngine: Get.find<TimerEngineService>()),
      );
      Get.put<HomeViewModel>(
        HomeViewModel(
          subjectRepository: subjectRepo,
          sessionRepository: sessionRepo,
          plannerRepository: plannerRepo,
          goalStreakRepository: goalRepo,
          nowProvider: () => fixedNow,
        ),
      );
      Get.put<StudyTimerViewModel>(
        StudyTimerViewModel(
          subjectRepository: subjectRepo,
          settingsRepository: Get.find<SettingsRepository>(),
        ),
      );
      Get.put<SubjectsViewModel>(
        SubjectsViewModel(
          subjectRepository: subjectRepo,
          sessionRepository: sessionRepo,
          nowProvider: () => fixedNow,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const MainShellView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Afternoon!'), findsOneWidget);
      expect(find.text('Tuesday, 12 May'), findsOneWidget);
      expect(find.text('63%'), findsOneWidget);
      expect(find.text('2h 30m'), findsWidgets);
      expect(find.text('1h 30m to go', findRichText: true), findsOneWidget);
      expect(find.text('Revise integration by parts'), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('View stats'), findsOneWidget);

      // Toggle task completion via PmCheckCircle widget
      final taskBefore = (await plannerRepo.getAllTasks()).first;
      expect(taskBefore.isCompleted, isFalse);

      await tester.ensureVisible(find.byType(PmCheckCircle).first);
      await tester.tap(find.byType(PmCheckCircle).first);
      await tester.pumpAndSettle();

      final taskAfter = (await plannerRepo.getAllTasks()).first;
      expect(taskAfter.isCompleted, isTrue);

      // Tapping another weekday in the date strip dynamically updates selected date & day stats
      await tester.ensureVisible(find.text('13'));
      await tester.tap(find.text('13'));
      await tester.pumpAndSettle();
      expect(find.text('Wednesday, 13 May'), findsOneWidget);
      expect(find.text("Day's Progress"), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // Tap back to 12 May
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(find.text('Tuesday, 12 May'), findsOneWidget);
      expect(find.text("Today's Progress"), findsOneWidget);

      // Switch tabs via bottom nav
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your focus mode'), findsOneWidget);

      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();
      expect(find.text('Active (2)'), findsOneWidget);

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.text('Statistics (Upcoming Section)'), findsOneWidget);

      // Return to Home and verify Settings route navigation works
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      await _disposeWidgetTree(tester);
    });
  });
}
