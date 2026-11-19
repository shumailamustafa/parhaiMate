import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:parhaimate/app/app.dart';
import 'package:parhaimate/app/bindings/initial_binding.dart';
import 'package:parhaimate/app/lifecycle/app_lifecycle_handler.dart';
import 'package:parhaimate/app/routes/app_routes.dart';
import 'package:parhaimate/core/services/timer_engine_service.dart';
import 'package:parhaimate/core/theme/app_colors.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';
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

  group('Section 5.4 Subjects & Subject Details', () {
    testWidgets(
        'renders empty Subjects state, validates blank Add Subject form, and creates a subject',
        (tester) async {
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.home,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();

      expect(find.text('My Subjects'), findsOneWidget);
      expect(find.text('No subjects yet'), findsOneWidget);

      // Navigate to Add Subject from empty state CTA
      await tester.tap(find.text('Add Subject'));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);

      // Submit blank -> shows validation error
      await tester.tap(find.text('Save Subject'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a subject name'), findsOneWidget);

      // Typing a name clears the validation error dynamically
      await tester.enterText(find.byType(TextField).first, 'Physics');
      await tester.pumpAndSettle();
      expect(find.text('Enter a subject name'), findsNothing);

      // Verify initial selected icon is sigma, then tap atom and assert visual selection moves!
      final sigmaKey = find.byKey(const ValueKey<String>('subject_icon_sigma'));
      final atomKey = find.byKey(const ValueKey<String>('subject_icon_atom'));
      expect(
        find.descendant(
          of: sigmaKey,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: atomKey,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );

      await tester.ensureVisible(atomKey);
      await tester.tap(atomKey);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: sigmaKey,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: atomKey,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      final atomMaterial = tester.widget<Material>(
        find.descendant(of: atomKey, matching: find.byType(Material)).first,
      );
      expect(atomMaterial.color, AppColors.primary);

      // Pick Triangle identifier and verify chip border highlights dynamically
      await tester.ensureVisible(find.text('Triangle'));
      await tester.tap(find.text('Triangle'));
      await tester.pumpAndSettle();

      // Test both + and - weekly target stepper dynamic updates
      expect(find.text('5h per week'), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.add_rounded).last);
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('330 min'), findsOneWidget);
      expect(find.text('5h 30m per week'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('300 min'), findsOneWidget);
      expect(find.text('5h per week'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('330 min'), findsOneWidget);

      await tester.tap(find.text('Save Subject'));
      await tester.pumpAndSettle();

      // Back on My Subjects showing newly saved subject card & chosen atom icon
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.byIcon(SubjectIconKey.atom.iconData), findsOneWidget);
      expect(
        find.text('0m / 5h 30m', findRichText: true),
        findsOneWidget,
      );

      final created = (await Get.find<SubjectRepository>().getSubjects()).first;
      expect(created.iconKey, SubjectIconKey.atom);
      expect(created.identifier, SubjectIdentifier.triangle);
      expect(created.targetMinutes, 330);

      await _disposeWidgetTree(tester);
    });

    testWidgets(
        'supports search no-results, Archive/Restore, Subject Details chart & Delete confirmation',
        (tester) async {
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

      final nowUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
      final sessionId = await sessionRepo.createActiveSession(
        subjectId: mathId,
        mode: TimerMode.pomodoro,
        startedAtMs: nowUtc - 50 * 60 * 1000,
      );
      await sessionRepo.completeSession(
        sessionId: sessionId,
        endedAtMs: nowUtc,
        durationSeconds: 50 * 60,
      );

      await plannerRepo.createTask(
        subjectId: mathId,
        title: 'Chapter 4 problems',
        scheduledDate: '2026-05-12',
        targetMinutes: 45,
      );

      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.home,
          initialBinding: binding,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();

      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Archived (0)'), findsOneWidget);

      // Search with no matches -> empty search state -> Clear search
      await tester.enterText(find.byType(TextField).first, 'history');
      await tester.pumpAndSettle();
      expect(find.text('No subjects match "history"'), findsOneWidget);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Mathematics'), findsOneWidget);

      // Open Subject Details
      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(find.text('Study Statistics'), findsOneWidget);
      expect(find.text('1 session'), findsOneWidget);
      expect(find.text('50m'), findsWidgets);
      expect(find.text('Start Studying This Subject'), findsOneWidget);

      // Archive from bottom button -> changes label to Restore Subject
      await tester.ensureVisible(find.text('Archive Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Subject'));
      await tester.pumpAndSettle();

      expect(find.text('Restore Subject'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);

      // Back to My Subjects -> verify Archived(1) tab displays the archived subject dynamically
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Active (0)'), findsOneWidget);
      expect(find.text('Archived (1)'), findsOneWidget);
      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Mathematics'), findsOneWidget);

      // Open archived Subject Details -> Restore back
      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Restore Subject'));
      await tester.tap(find.text('Restore Subject'));
      await tester.pumpAndSettle();
      expect(find.text('Archive Subject'), findsOneWidget);

      // Edit Subject -> change icon to Code and name to Calculus II, then verify Subject Details updates!
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit Subject'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Calculus II');
      final codeKey = find.byKey(const ValueKey<String>('subject_icon_code'));
      await tester.ensureVisible(codeKey);
      await tester.tap(codeKey);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Subject'));
      await tester.pumpAndSettle();

      expect(find.text('Calculus II'), findsWidgets);
      expect(find.byIcon(SubjectIconKey.code.iconData), findsOneWidget);

      // Open Subject actions bottom sheet -> Delete Subject -> Confirmation dialog
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Subject actions'), findsOneWidget);

      await tester.tap(find.text('Delete Subject'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Calculus II?'), findsOneWidget);
      expect(
        find.textContaining('1 sessions and 1 planned tasks will be deleted'),
        findsOneWidget,
      );

      await tester.tap(find.text('Delete Subject').last);
      await tester.pumpAndSettle();

      final remaining = await subjectRepo.getSubjects();
      expect(remaining, isEmpty);

      await _disposeWidgetTree(tester);
    });
  });
}
