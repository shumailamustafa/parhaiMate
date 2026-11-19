import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:parhaimate/app/app.dart';
import 'package:parhaimate/app/bindings/initial_binding.dart';
import 'package:parhaimate/app/lifecycle/app_lifecycle_handler.dart';
import 'package:parhaimate/app/routes/app_routes.dart';
import 'package:parhaimate/core/services/timer_engine_service.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';

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

  group('Section 5.1 Launch, Onboarding & Component Library', () {
    testWidgets('Splash displays branding and navigates first-time user to Onboarding',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.splash,
          initialBinding: InitialBinding(database: db),
        ),
      );

      expect(find.text('ParhaiMate'), findsOneWidget);
      expect(find.text('Your Personal Study Companion'), findsOneWidget);

      // Advance past the 700ms splash delay and PageView settle.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.text('Focus on What Matters.'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Onboarding advances through 3 slides and persists completion on Get Started',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.onboarding,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1
      expect(find.text('Focus on What Matters.'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Slide 2
      expect(find.text('Plan Your Study Routine.'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Slide 3
      expect(find.text('See Your Progress Grow.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Section 5.1 Ready'), findsOneWidget);
      final completed =
          await Get.find<SettingsRepository>().isOnboardingCompleted();
      expect(completed, isTrue);
    });

    testWidgets('Onboarding Skip completes onboarding and navigates to Home preview',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.onboarding,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Section 5.1 Ready'), findsOneWidget);
      final completed =
          await Get.find<SettingsRepository>().isOnboardingCompleted();
      expect(completed, isTrue);
    });

    testWidgets('Component Library route renders interactively', (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.components,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Component Library'), findsOneWidget);
      expect(find.text('Foundations'), findsOneWidget);
      expect(find.text('Buttons'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No sessions yet'), findsOneWidget);
    });
  });
}
