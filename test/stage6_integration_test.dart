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
import 'package:parhaimate/core/widgets/pm_buttons.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';
import 'package:parhaimate/features/backup/services/backup_service.dart';
import 'package:parhaimate/features/backup/services/report_service.dart';

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
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late AppDatabase db;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureDefaultsSeeded();
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

  group('Stage 6 Full Routing, Bindings & End-to-End Integration', () {
    test('all AppRoutes entries are registered uniquely in AppPages without duplicates', () {
      const expectedRoutes = <String>[
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.home,
        AppRoutes.timer,
        AppRoutes.sessionSetup,
        AppRoutes.activeFocus,
        AppRoutes.sessionSummary,
        AppRoutes.subjects,
        AppRoutes.addSubject,
        AppRoutes.subjectDetails,
        AppRoutes.editSubject,
        AppRoutes.planner,
        AppRoutes.addTask,
        AppRoutes.editTask,
        AppRoutes.calendar,
        AppRoutes.progress,
        AppRoutes.sessionHistory,
        AppRoutes.goals,
        AppRoutes.achievements,
        AppRoutes.settings,
        AppRoutes.timerPresets,
        AppRoutes.createPreset,
        AppRoutes.editPreset,
        AppRoutes.dailyGoalConfig,
        AppRoutes.weeklyGoalConfig,
        AppRoutes.exportBackup,
        AppRoutes.importBackup,
        AppRoutes.studyReport,
        AppRoutes.privacyPolicy,
        AppRoutes.navigationFlow,
        AppRoutes.components,
      ];

      final registeredNames = AppPages.pages.map((p) => p.name).toList();
      expect(registeredNames.toSet().length, registeredNames.length);
      for (final route in expectedRoutes) {
        expect(registeredNames, contains(route));
      }
      expect(registeredNames.length, expectedRoutes.length);
    });

    test('InitialBinding wires all core repositories, timer engine, and backup/report services', () {
      InitialBinding(database: db).dependencies();

      expect(Get.isRegistered<AppDatabase>(), isTrue);
      expect(Get.isRegistered<SubjectRepository>(), isTrue);
      expect(Get.isRegistered<SessionRepository>(), isTrue);
      expect(Get.isRegistered<PlannerRepository>(), isTrue);
      expect(Get.isRegistered<GoalStreakRepository>(), isTrue);
      expect(Get.isRegistered<AchievementRepository>(), isTrue);
      expect(Get.isRegistered<PresetRepository>(), isTrue);
      expect(Get.isRegistered<SettingsRepository>(), isTrue);
      expect(Get.isRegistered<TimerEngineService>(), isTrue);
      expect(Get.isRegistered<AppLifecycleHandler>(), isTrue);
      expect(Get.isRegistered<BackupService>(), isTrue);
      expect(Get.isRegistered<ReportService>(), isTrue);
    });

    testWidgets(
      'end-to-end journey: Splash -> Onboarding Skip -> Create Subject -> Focus Timer -> Session Summary -> Progress',
      (tester) async {
        await tester.pumpWidget(
          ParhaiMateRootApp(
            initialRoute: AppRoutes.splash,
            initialBinding: InitialBinding(database: db),
          ),
        );

        expect(find.text('ParhaiMate'), findsOneWidget);
        expect(find.text('Powered by Coding District'), findsOneWidget);

        // Splash automatically transitions to Onboarding.
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpAndSettle();
        expect(find.text('Skip'), findsOneWidget);

        // Skip Onboarding -> Home Dashboard.
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(find.text('Ready to make today productive?'), findsOneWidget);

        // Switch to Subjects tab and create a new subject.
        await tester.tap(find.text('Subjects'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Add Subject'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Data Structures');
        await tester.pump();
        await tester.tap(find.text('Save Subject'));
        await tester.pumpAndSettle();
        expect(find.text('Data Structures'), findsOneWidget);

        // Switch to Timer tab, proceed to Session Setup, and start session.
        await tester.tap(find.text('Timer'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Start Studying'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start Studying'));
        await tester.pumpAndSettle();
        expect(find.text('Set Up Your Session'), findsOneWidget);

        await tester.ensureVisible(find.text('Start Session'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start Session'));
        await tester.pumpAndSettle();
        expect(find.text('Finish Session'), findsOneWidget);

        // Let the live timer advance 3 seconds then finish session cleanly.
        await tester.pump(const Duration(seconds: 3));
        await tester.ensureVisible(find.text('Finish Session'));
        await tester.tap(find.text('Finish Session'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Finish Session').last);
        await tester.pumpAndSettle();

        expect(find.text('Add Notes'), findsOneWidget);
        await tester.ensureVisible(find.text('Save Session'));
        await tester.tap(find.text('Save Session'));
        await tester.pumpAndSettle();

        final sessions =
            await Get.find<SessionRepository>().getCompletedSessions();
        expect(sessions.length, 1);

        await _disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'end-to-end Settings journey: Home -> Settings -> Daily Goal -> About -> Privacy Policy',
      (tester) async {
        await db.settingsDao.setValue(
          AppDatabase.keyOnboardingCompleted,
          'true',
        );

        await tester.pumpWidget(
          ParhaiMateRootApp(
            initialRoute: AppRoutes.home,
            initialBinding: InitialBinding(database: db),
          ),
        );
        await tester.pumpAndSettle();

        // Open Settings from Home gear button.
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);

        // Configure Daily Study Goal to 3h and return.
        await tester.tap(find.text('Daily Study Goal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('3h'));
        await tester.pump();
        await tester.tap(find.text('Save Goal'));
        await tester.pumpAndSettle();
        expect(find.text('3h'), findsOneWidget);

        // Open About sheet and confirm Coding District attribution.
        await tester.scrollUntilVisible(find.text('About ParhaiMate'), 200);
        await tester.tap(find.text('About ParhaiMate'));
        await tester.pumpAndSettle();
        expect(find.text('Powered by Coding District'), findsAtLeastNWidgets(1));
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Open Privacy Policy and return cleanly.
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Android Auto Backup'), findsOneWidget);

        await _disposeWidgetTree(tester);
      },
    );
  });
}
