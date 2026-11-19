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
import 'package:parhaimate/domain/enums/domain_enums.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';
import 'package:parhaimate/features/timer/viewmodels/active_focus_viewmodel.dart';
import 'package:parhaimate/features/timer/viewmodels/session_setup_viewmodel.dart';
import 'package:parhaimate/features/timer/views/active_focus_view.dart';
import 'package:parhaimate/features/timer/views/session_setup_view.dart';

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
  // Allow Drift's zero-duration StreamQueryStore cleanup timer to settle.
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

  group('Section 5.3 Study Timer, Session Setup, Active Focus & Summary', () {
    testWidgets(
        'Study Timer renders modes, lets user start without selecting a subject, and navigates to Session Setup',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.home,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      expect(find.text('Choose your focus mode'), findsOneWidget);
      expect(find.text('Focus Timer'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);
      expect(find.text('Pomodoro'), findsOneWidget);

      // Select Focus Timer mode and 45 min chip without choosing any subject.
      await tester.tap(find.text('Focus Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start Studying'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Studying'));
      await tester.pumpAndSettle();

      expect(find.text('Set Up Your Session'), findsOneWidget);
      expect(find.text('General Study'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'Session Setup adapts dynamically for Stopwatch and Pomodoro and starts a Pomodoro session',
        (tester) async {
      final binding = InitialBinding(database: db);
      binding.dependencies();

      final subjectId = await Get.find<SubjectRepository>().createSubject(
        name: 'Mathematics',
        identifier: SubjectIdentifier.circle,
        iconKey: SubjectIconKey.sigma,
        targetMinutes: 300,
      );

      final fixedNow = DateTime(2026, 5, 12, 15, 20);
      Get.put<SessionSetupViewModel>(
        SessionSetupViewModel(
          subjectRepository: Get.find<SubjectRepository>(),
          settingsRepository: Get.find<SettingsRepository>(),
          timerEngine: Get.find<TimerEngineService>(),
          nowProvider: () => fixedNow,
          initialArgs: <String, dynamic>{
            'mode': TimerMode.focus,
            'subjectId': subjectId,
            'focusMinutes': 25,
          },
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const SessionSetupView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsWidgets);
      expect(find.text('25m'), findsOneWidget);

      // Switch to Stopwatch -> duration selector hides & summary shows No time limit
      await tester.tap(find.text('Stopwatch').first);
      await tester.pumpAndSettle();
      expect(find.text('No time limit'), findsOneWidget);
      expect(find.text('Pomodoro settings'), findsNothing);

      // Switch to Pomodoro -> steppers and 1h 55m (4*25 + 3*5) appear
      await tester.tap(find.text('Pomodoro').first);
      await tester.pumpAndSettle();
      expect(find.text('Pomodoro settings'), findsOneWidget);
      expect(find.text('1h 55m'), findsOneWidget);
      expect(find.text('4 cycles'), findsOneWidget);

      // Start session -> enters Active Focus screen
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Focusing'), findsOneWidget);
      expect(find.text('Cycle 1 of 4'), findsOneWidget);
      expect(find.text('Finish Session'), findsOneWidget);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'Active Focus pause/resume, cancel confirmation dialog, and finish -> Session Summary + Add Notes flow work',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.sessionSetup,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Start unassigned Focus Timer session directly from Session Setup.
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Focusing'), findsOneWidget);
      expect(find.text('General Study'), findsOneWidget);

      // Pause & resume via central 72px navy button
      await tester.ensureVisible(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Focusing'), findsOneWidget);

      // Open Cancel confirmation dialog and keep studying
      await tester.ensureVisible(find.text('Cancel Session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel Session'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this session?'), findsOneWidget);
      await tester.tap(find.text('Keep Studying'));
      await tester.pumpAndSettle();
      expect(find.text('Focusing'), findsOneWidget);

      // Open Finish confirmation dialog and confirm
      await tester.ensureVisible(find.text('Finish Session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Session'));
      await tester.pumpAndSettle();
      expect(find.text('Finish this session?'), findsOneWidget);

      // Tap dialog's primary 'Finish Session' button (last one in overlay)
      await tester.tap(find.text('Finish Session').last);
      await tester.pumpAndSettle();

      // Lands on Session Summary
      expect(find.text('Session Completed'), findsOneWidget);
      expect(find.text('Nice work on General Study'), findsOneWidget);
      expect(find.text('Session statistics'), findsOneWidget);

      // Open Add Notes sheet and persist a note
      await tester.ensureVisible(find.text('Add Notes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Session notes'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        'Completed all practice derivatives cleanly.',
      );
      await tester.ensureVisible(find.text('Save notes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Completed all practice derivatives cleanly.'),
        findsOneWidget,
      );

      final savedSessions =
          await Get.find<SessionRepository>().getCompletedSessions();
      expect(savedSessions.length, 1);
      expect(
        savedSessions.first.notes,
        'Completed all practice derivatives cleanly.',
      );

      // Save Session returns cleanly to Home Dashboard
      await tester.ensureVisible(find.text('Save Session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      expect(find.text('Ready to make today productive?'), findsOneWidget);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'Active Focus countdown and Stopwatch update displayed clock every second without pausing',
        (tester) async {
      var fakeNowMs = 1700000000000;
      final binding = InitialBinding(database: db);
      binding.dependencies();

      final engine = TimerEngineService(
        sessionRepository: Get.find<SessionRepository>(),
        activeTimerDao: db.activeTimerDao,
        nowMsProvider: () => fakeNowMs,
      );
      await Get.delete<TimerEngineService>(force: true);
      Get.put<TimerEngineService>(engine, permanent: true);

      Get.put<ActiveFocusViewModel>(
        ActiveFocusViewModel(
          timerEngine: engine,
          subjectRepository: Get.find<SubjectRepository>(),
          sessionRepository: Get.find<SessionRepository>(),
        ),
      );

      // 1. Focus Timer countdown ticks down live
      await engine.startSession(mode: TimerMode.focus, focusMinutes: 25);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          getPages: AppPages.pages,
          home: const ActiveFocusView(),
        ),
      );
      await tester.pump();
      expect(find.text('25:00'), findsOneWidget);

      fakeNowMs += 3000;
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('24:57'), findsOneWidget);

      await engine.cancelSession();

      // 2. Stopwatch counts up live
      await engine.startSession(mode: TimerMode.stopwatch);
      await tester.pump();
      expect(find.text('00:00'), findsOneWidget);

      fakeNowMs += 4000;
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:04'), findsOneWidget);

      await _disposeWidgetTree(tester);
    });
  });
}
