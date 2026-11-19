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
import 'package:parhaimate/features/calendar/viewmodels/calendar_viewmodel.dart';
import 'package:parhaimate/features/calendar/views/calendar_view.dart';
import 'package:parhaimate/features/planner/viewmodels/planner_viewmodel.dart';
import 'package:parhaimate/features/planner/views/study_planner_view.dart';

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

  group('Section 5.5 Study Planner & Calendar', () {
    testWidgets(
        'renders empty planner, validates Add Task, dynamically updates Date/Time/Duration controls, and toggles completion',
        (tester) async {
      final binding = InitialBinding(database: db);
      binding.dependencies();

      await Get.find<SubjectRepository>().createSubject(
        name: 'Mathematics',
        identifier: SubjectIdentifier.circle,
        iconKey: SubjectIconKey.sigma,
        targetMinutes: 300,
      );

      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.planner,
          initialBinding: binding,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsOneWidget);
      expect(find.text('No study tasks yet'), findsOneWidget);

      // Navigate to Add Study Task
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
      expect(find.text('Add Study Task'), findsOneWidget);

      // Submit blank title -> shows inline validation error & typing clears it
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a task title'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'Revise integration by parts',
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter a task title'), findsNothing);

      // Pick subject dynamically
      await tester.tap(find.text('General Study'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();
      expect(find.text('Mathematics'), findsOneWidget);

      // Open Choose date bottom sheet -> tap Tomorrow, then re-open -> tap Today!
      await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Choose date'), findsOneWidget);

      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      final tomorrowStr = DateTimeUtils.formatFullDate(
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(find.text(tomorrowStr), findsOneWidget);

      await tester.tap(find.text(tomorrowStr));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      final todayStr = DateTimeUtils.formatFullDate(DateTime.now());
      expect(find.text(todayStr), findsOneWidget);

      // Choose Time dynamically via Choose time sheet
      await tester.ensureVisible(find.text('4:00 PM'));
      await tester.tap(find.text('4:00 PM'));
      await tester.pumpAndSettle();
      expect(find.text('Choose time'), findsOneWidget);
      await tester.tap(find.text('6:00 PM'));
      await tester.pumpAndSettle();
      expect(find.text('6:00 PM'), findsOneWidget);

      // Change Target duration via chip & stepper dynamically
      await tester.ensureVisible(find.text('45 min'));
      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();
      expect(find.text('45 minutes'), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.add_rounded).last);
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('60 minutes'), findsOneWidget);
      expect(find.text('60 min'), findsWidgets);

      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Planner displays newly added task
      expect(find.text('Revise integration by parts'), findsOneWidget);
      expect(find.text('0 of 1 tasks done · 1h planned'), findsOneWidget);

      // Toggle completion -> moves under DONE section dynamically
      await tester.tap(find.byType(PmCheckCircle).first);
      await tester.pumpAndSettle();
      expect(find.text('1 of 1 tasks done · 1h planned'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);

      // Switch to Completed tab dynamically
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.text('Revise integration by parts'), findsOneWidget);

      // Tap task -> Edit Study Task -> Delete confirmation removes task
      await tester.tap(find.text('Revise integration by parts'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Study Task'), findsOneWidget);
      expect(find.text('Start studying now'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Delete this task?'), findsOneWidget);
      await tester.tap(find.text('Delete Task'));
      await tester.pumpAndSettle();

      expect(find.text('No study tasks yet'), findsOneWidget);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'Study Planner switches Upcoming tab & empty day state, and Calendar navigates months & dates dynamically',
        (tester) async {
      final fixedNow = DateTime(2026, 5, 12, 10, 0);
      final binding = InitialBinding(database: db);
      binding.dependencies();

      final subjectRepo = Get.find<SubjectRepository>();
      final sessionRepo = Get.find<SessionRepository>();
      final plannerRepo = Get.find<PlannerRepository>();

      final mathId = await subjectRepo.createSubject(
        name: 'Mathematics',
        identifier: SubjectIdentifier.circle,
        iconKey: SubjectIconKey.sigma,
        targetMinutes: 300,
      );

      // Task on Today (12 May) and Upcoming (13 May)
      await plannerRepo.createTask(
        subjectId: mathId,
        title: 'Linear algebra quiz',
        scheduledDate: '2026-05-12',
        scheduledTime: '16:00',
        targetMinutes: 45,
      );
      await plannerRepo.createTask(
        subjectId: mathId,
        title: 'Eigenvalues reading',
        scheduledDate: '2026-05-13',
        scheduledTime: '18:00',
        targetMinutes: 30,
      );

      // Session on April 18, 2026
      final aprilStart =
          DateTime(2026, 4, 18, 8, 0).toUtc().millisecondsSinceEpoch;
      final aprilSessionId = await sessionRepo.createActiveSession(
        subjectId: mathId,
        mode: TimerMode.focus,
        startedAtMs: aprilStart,
      );
      await sessionRepo.completeSession(
        sessionId: aprilSessionId,
        endedAtMs: aprilStart + 40 * 60 * 1000,
        durationSeconds: 40 * 60,
      );

      Get.put<PlannerViewModel>(
        PlannerViewModel(
          plannerRepository: plannerRepo,
          subjectRepository: subjectRepo,
          nowProvider: () => fixedNow,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const StudyPlannerView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('11 May – 17 May'), findsOneWidget);
      expect(find.text('Linear algebra quiz'), findsOneWidget);

      // Upcoming tab shows Tomorrow task dynamically
      await tester.tap(find.text('Upcoming'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Eigenvalues reading'), findsOneWidget);

      // Tap Sat 16 (no tasks planned) -> tab renames to Sat, 16 May & shows day empty state
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(find.text('Sat, 16 May'), findsOneWidget);
      expect(find.text('Nothing planned for Sat, 16 May'), findsOneWidget);

      // Open Calendar directly with fixedNow = May 12, 2026
      Get.put<CalendarViewModel>(
        CalendarViewModel(
          sessionRepository: sessionRepo,
          plannerRepository: plannerRepo,
          subjectRepository: subjectRepo,
          nowProvider: () => fixedNow,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const CalendarView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('May 2026'), findsOneWidget);
      expect(find.text('Tuesday, 12 May'), findsOneWidget);
      expect(find.text('Linear algebra quiz'), findsOneWidget);

      // Tap May 3 (empty day) -> updates date & shows No study activity state
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(find.text('Sunday, 3 May'), findsOneWidget);
      expect(find.text('No study activity on Sun, 3 May'), findsOneWidget);

      // Open Select month bottom sheet and jump to Apr 2026
      await tester.ensureVisible(find.text('May 2026'));
      await tester.tap(find.text('May 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Select month'), findsOneWidget);

      await tester.tap(find.text('Apr'));
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);

      // Tap April 18 -> shows 40m Study time & 1 session dynamically!
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      expect(find.text('Saturday, 18 April'), findsOneWidget);
      expect(find.text('40m'), findsWidgets);

      await _disposeWidgetTree(tester);
    });
  });
}
