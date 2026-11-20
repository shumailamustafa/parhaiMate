import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:parhaimate/app/bindings/initial_binding.dart';
import 'package:parhaimate/app/lifecycle/app_lifecycle_handler.dart';
import 'package:parhaimate/app/routes/app_pages.dart';
import 'package:parhaimate/core/services/timer_engine_service.dart';
import 'package:parhaimate/core/theme/app_theme.dart';
import 'package:parhaimate/core/widgets/pm_buttons.dart';
import 'package:parhaimate/data/database/app_database.dart';
import 'package:parhaimate/domain/enums/domain_enums.dart';
import 'package:parhaimate/domain/repositories/repositories.dart';
import 'package:parhaimate/features/backup/services/backup_service.dart';
import 'package:parhaimate/features/backup/services/report_service.dart';
import 'package:parhaimate/features/backup/viewmodels/backup_viewmodel.dart';
import 'package:parhaimate/features/backup/viewmodels/export_report_viewmodel.dart';
import 'package:parhaimate/features/backup/views/export_backup_view.dart';
import 'package:parhaimate/features/backup/views/export_report_view.dart';
import 'package:parhaimate/features/backup/views/import_backup_view.dart';
import 'package:parhaimate/features/settings/viewmodels/goal_config_viewmodel.dart';
import 'package:parhaimate/features/settings/viewmodels/presets_viewmodel.dart';
import 'package:parhaimate/features/settings/viewmodels/settings_viewmodel.dart';
import 'package:parhaimate/features/settings/views/goal_config_views.dart';
import 'package:parhaimate/features/settings/views/navigation_flow_view.dart';
import 'package:parhaimate/features/settings/views/presets_views.dart';
import 'package:parhaimate/features/settings/views/privacy_policy_view.dart';
import 'package:parhaimate/features/settings/views/settings_view.dart';

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

Widget _buildHostApp({required Widget home}) {
  return GetMaterialApp(
    theme: AppTheme.light,
    getPages: AppPages.pages,
    home: home,
  );
}

Future<void> _waitForCondition(
  WidgetTester tester,
  bool Function() isDone,
) async {
  for (var i = 0; i < 20; i++) {
    if (isDone()) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
  }
}

Future<void> _seedCompletedSession({
  required SessionRepository sessionRepository,
  required int? subjectId,
  required TimerMode mode,
  required int startedAtMs,
  required int endedAtMs,
  required int durationSeconds,
  String? notes,
}) async {
  final sessionId = await sessionRepository.createActiveSession(
    subjectId: subjectId,
    mode: mode,
    startedAtMs: startedAtMs,
    notes: notes,
  );
  await sessionRepository.completeSession(
    sessionId: sessionId,
    endedAtMs: endedAtMs,
    durationSeconds: durationSeconds,
    notes: notes,
  );
}

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureDefaultsSeeded();
    tempDir = await Directory.systemTemp.createTemp('parhaimate_57_test_');
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
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Section 5.7 Settings, Goals, Presets, Backup & Reporting', () {
    testWidgets(
      'Settings shows Session Alerts toggle, updates Default Timer Mode dynamically, clears history cleanly, and gates Delete All App Data behind DELETE',
      (tester) async {
        final binding = InitialBinding(database: db);
        binding.dependencies();

        final subjId = await Get.find<SubjectRepository>().createSubject(
          name: 'Physics',
          identifier: SubjectIdentifier.circle,
          iconKey: SubjectIconKey.atom,
          targetMinutes: 180,
        );
        final now = DateTime.now().toUtc();
        await _seedCompletedSession(
          sessionRepository: Get.find<SessionRepository>(),
          subjectId: subjId,
          mode: TimerMode.focus,
          startedAtMs: now.subtract(const Duration(minutes: 40)).millisecondsSinceEpoch,
          endedAtMs: now.millisecondsSinceEpoch,
          durationSeconds: 2400,
        );

        Get.put<SettingsViewModel>(
          SettingsViewModel(
            settingsRepository: Get.find<SettingsRepository>(),
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            presetRepository: Get.find<PresetRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );

        await tester.pumpWidget(_buildHostApp(home: const SettingsView()));
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Session Alerts'), findsOneWidget);
        expect(find.text('Notification Preferences'), findsNothing);
        expect(find.text('Component Library'), findsNothing);
        expect(find.text('Navigation Flow'), findsNothing);
        expect(find.text('Export CSV'), findsNothing);
        expect(find.text('Export PDF'), findsNothing);
        expect(find.text('Export Study Report'), findsOneWidget);
        expect(find.text('Default Timer Mode'), findsOneWidget);
        expect(find.text('Pomodoro'), findsOneWidget);

        // Verify About ParhaiMate omits Navigation Flow and includes Coding District branding.
        await tester.scrollUntilVisible(
          find.text('About ParhaiMate'),
          200,
        );
        await tester.tap(find.text('About ParhaiMate'));
        await tester.pumpAndSettle();
        expect(find.text('Navigation Flow'), findsNothing);
        expect(find.text('Powered by Coding District'), findsAtLeastNWidgets(1));
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Scroll to bottom of Settings to confirm Powered by Coding District footer.
        await tester.scrollUntilVisible(
          find.text('Powered by Coding District'),
          200,
        );
        expect(find.text('Powered by Coding District'), findsOneWidget);

        // Change Default Timer Mode dynamically via bottom sheet.
        await tester.ensureVisible(find.text('Default Timer Mode'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Default Timer Mode'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Focus Timer'));
        await tester.pumpAndSettle();
        expect(find.text('Focus Timer'), findsOneWidget);

        // Clear Study History preserves subjects while clearing sessions.
        await tester.scrollUntilVisible(
          find.text('Clear Study History'),
          200,
        );
        await tester.tap(find.text('Clear Study History'));
        await tester.pumpAndSettle();
        expect(find.text('Clear study history?'), findsOneWidget);
        await tester.tap(find.text('Clear History'));
        await tester.pumpAndSettle();
        // Wait for the floating SnackBar toast (2s) to dismiss so bottom rows stay unhindered.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(await Get.find<SessionRepository>().getCompletedSessions(), isEmpty);
        expect(
          (await Get.find<SubjectRepository>().getSubjects()).length,
          1,
        );

        // Delete All App Data disabled until 'DELETE' is typed cleanly.
        await tester.scrollUntilVisible(
          find.text('Delete All App Data'),
          200,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete All App Data'));
        await tester.pumpAndSettle();
        expect(find.text('Delete all app data?'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'wrong');
        await tester.pump();
        await tester.tap(find.text('Delete Everything'));
        await tester.pump();
        expect(find.text('Delete all app data?'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'DELETE');
        await tester.pump();
        await tester.tap(find.text('Delete Everything'));
        await tester.pumpAndSettle();

        expect(await Get.find<SubjectRepository>().getSubjects(), isEmpty);

        await _disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'Daily & Weekly Goal Config steppers and chips dynamically update UI and persist goals',
      (tester) async {
        final binding = InitialBinding(database: db);
        binding.dependencies();

        Get.put<GoalConfigViewModel>(
          GoalConfigViewModel(
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );

        await tester.pumpWidget(_buildHostApp(home: const DailyGoalConfigView()));
        await tester.pumpAndSettle();

        expect(find.text('Daily Study Goal'), findsOneWidget);
        expect(find.text('4h'), findsWidgets);

        await tester.tap(find.text('2h'));
        await tester.pump();
        expect(
          find.text("Today you've studied 0m, 0% of this goal"),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Increase goal'));
        await tester.pump();
        expect(find.text('2h 30m'), findsOneWidget);

        await tester.tap(find.text('Save Goal'));
        await tester.pumpAndSettle();
        expect(await Get.find<GoalStreakRepository>().getDailyGoalMinutes(), 150);

        await _disposeWidgetTree(tester);

        // Now verify Weekly Goal Config independently.
        final binding2 = InitialBinding(database: db);
        binding2.dependencies();
        Get.put<GoalConfigViewModel>(
          GoalConfigViewModel(
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );

        await tester.pumpWidget(
          _buildHostApp(home: const WeeklyGoalConfigView()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Weekly Study Goal'), findsOneWidget);
        await tester.tap(find.text('15h'));
        await tester.pump();
        await tester.tap(find.text('Save Goal'));
        await tester.pumpAndSettle();

        expect(
          await Get.find<GoalStreakRepository>().getWeeklyGoalMinutes(),
          900,
        );

        await _disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'Timer Presets list, create validation, dynamic Focus/Pomodoro/Stopwatch duration calculation, delete dialog & empty state',
      (tester) async {
        final binding = InitialBinding(database: db);
        binding.dependencies();

        Get.put<PresetsViewModel>(
          PresetsViewModel(presetRepository: Get.find<PresetRepository>()),
        );

        await tester.pumpWidget(_buildHostApp(home: const PresetsListView()));
        await tester.pumpAndSettle();

        // Seeded default presets should be listed.
        expect(find.text('Classic Pomodoro'), findsOneWidget);
        expect(find.text('Deep Work'), findsOneWidget);

        // Open Create Preset form.
        await tester.tap(find.byTooltip('Add Preset'));
        await tester.pumpAndSettle();

        expect(find.text('New Preset'), findsOneWidget);
        // Save with empty name shows validation error and clears when typed.
        await tester.tap(find.text('Save Preset'));
        await tester.pump();
        expect(find.text('Enter a preset name'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Exam Sprint');
        await tester.pump();
        expect(find.text('Enter a preset name'), findsNothing);

        // Pomodoro default: 4*25 + 3*5 + 15 long break = 130m -> 2h 10m.
        expect(find.text('2h 10m'), findsOneWidget);
        expect(find.text('Short break'), findsOneWidget);

        // Switch to Focus Timer -> hides break steppers & updates Full session duration.
        await tester.tap(find.text('Focus Timer'));
        await tester.pump();
        expect(find.text('Short break'), findsNothing);
        expect(find.text('25m'), findsOneWidget);

        // Switch to Stopwatch -> hides Focus duration & shows 'No time limit'.
        await tester.tap(find.text('Stopwatch'));
        await tester.pump();
        expect(find.text('Focus duration'), findsNothing);
        expect(find.text('No time limit'), findsOneWidget);

        // Save Stopwatch preset and return to list.
        await tester.tap(find.text('Save Preset'));
        await tester.pumpAndSettle();

        expect(find.text('Exam Sprint'), findsOneWidget);

        // Delete all presets and verify empty state renders.
        final all = await Get.find<PresetRepository>().getPresets();
        for (final preset in all) {
          await Get.find<PresetRepository>().deletePreset(preset.id);
        }
        await tester.pumpAndSettle();
        expect(find.text('No timer presets'), findsOneWidget);

        await _disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'BackupService & Export/Import views export clean JSON, reject invalid/damaged files, and support Replace & Merge restores',
      (tester) async {
        final binding = InitialBinding(database: db);
        binding.dependencies();

        String? sharedPath;
        ({String name, String content})? nextPickedFile;

        final backupService = BackupService(
          database: db,
          goalStreakRepository: Get.find<GoalStreakRepository>(),
          settingsRepository: Get.find<SettingsRepository>(),
          achievementRepository: Get.find<AchievementRepository>(),
          exportDirectoryProvider: () async => tempDir,
          shareFileHandler: (filePath, _) async {
            sharedPath = filePath;
          },
          pickBackupFileHandler: () async => nextPickedFile,
        );

        final subjId = await Get.find<SubjectRepository>().createSubject(
          name: 'Algorithms',
          identifier: SubjectIdentifier.square,
          iconKey: SubjectIconKey.code,
          targetMinutes: 240,
        );
        final now = DateTime.now().toUtc();
        await _seedCompletedSession(
          sessionRepository: Get.find<SessionRepository>(),
          subjectId: subjId,
          mode: TimerMode.focus,
          startedAtMs: now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
          endedAtMs: now.millisecondsSinceEpoch,
          durationSeconds: 1800,
          notes: 'Binary trees',
        );
        await Get.find<PlannerRepository>().createTask(
          subjectId: subjId,
          title: 'Solve 5 DP problems',
          scheduledDate: '2026-11-20',
          targetMinutes: 60,
        );

        // Export flow test.
        Get.put<BackupViewModel>(
          BackupViewModel(
            backupService: backupService,
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );

        await tester.pumpWidget(_buildHostApp(home: const ExportBackupView()));
        await tester.pumpAndSettle();

        expect(find.text("What's included"), findsOneWidget);
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Backup'));
        await tester.pumpAndSettle();
        expect(find.text('Export backup?'), findsOneWidget);

        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Backup').last);
        await _waitForCondition(
          tester,
          () => Get.find<BackupViewModel>().exportStage.value ==
              ExportBackupStage.saved,
        );
        await tester.pumpAndSettle();
        expect(find.text('Backup saved'), findsOneWidget);

        await tester.tap(find.text('Share File'));
        await tester.pump();
        expect(sharedPath, isNotNull);
        final exportedJson =
            await tester.runAsync(() => File(sharedPath!).readAsString());
        expect(exportedJson, isNotNull);
        final decoded = jsonDecode(exportedJson!) as Map<String, dynamic>;
        expect(decoded.containsKey('activeTimerStates'), isFalse);
        expect((decoded['subjects'] as List<dynamic>).length, 1);
        expect((decoded['studySessions'] as List<dynamic>).length, 1);

        await _disposeWidgetTree(tester);

        // Mutate current DB (add a distinct subject and replace all later).
        final binding2 = InitialBinding(database: db);
        binding2.dependencies();

        await Get.find<SubjectRepository>().createSubject(
          name: 'Chemistry',
          identifier: SubjectIdentifier.triangle,
          iconKey: SubjectIconKey.flask,
          targetMinutes: 120,
        );

        final importVm = BackupViewModel(
          backupService: backupService,
          timerEngine: Get.find<TimerEngineService>(),
        );
        Get.put<BackupViewModel>(importVm);

        await tester.pumpWidget(_buildHostApp(home: const ImportBackupView()));
        await tester.pumpAndSettle();

        // 1. Non-.json file triggers "Couldn't read this file".
        nextPickedFile = (name: 'notes.txt', content: exportedJson);
        await tester.tap(find.text('Browse Files'));
        await tester.pumpAndSettle();
        expect(find.text("Couldn't read this file"), findsOneWidget);
        await tester.tap(find.text('Choose Another File'));
        await tester.pumpAndSettle();

        // 2. Malformed JSON triggers "Couldn't read this file".
        nextPickedFile = (name: 'bad.json', content: '{broken-json');
        await tester.tap(find.text('Browse Files'));
        await tester.pumpAndSettle();
        expect(find.text("Couldn't read this file"), findsOneWidget);
        await tester.tap(find.text('Choose Another File'));
        await tester.pumpAndSettle();

        // 3. Valid JSON missing ParhaiMate backup sections triggers "This backup is damaged".
        nextPickedFile = (
          name: 'damaged.json',
          content: '{"appName":"ParhaiMate","schemaVersion":1,"subjects":[]}',
        );
        await tester.tap(find.text('Browse Files'));
        await tester.pumpAndSettle();
        expect(find.text('This backup is damaged'), findsOneWidget);
        await tester.tap(find.text('Choose Another File'));
        await tester.pumpAndSettle();

        // 3. Valid JSON -> Merge first (keeps Chemistry + Algorithms without dupes).
        nextPickedFile = (name: 'backup.json', content: exportedJson);
        await tester.tap(find.text('Browse Files'));
        await tester.pumpAndSettle();
        expect(find.text('Restore options'), findsOneWidget);

        await tester.ensureVisible(find.text('Merge with current data'));
        await tester.tap(find.text('Merge with current data'));
        await tester.pump();
        await tester.tap(find.text('Restore Backup'));
        await tester.pumpAndSettle();
        expect(find.text('Backup restored'), findsOneWidget);

        final mergedSubjects =
            await Get.find<SubjectRepository>().getSubjects();
        expect(mergedSubjects.map((s) => s.name).toSet(), <String>{
          'Algorithms',
          'Chemistry',
        });

        // 4. Replace mode -> shows destructive confirmation & leaves only Algorithms.
        importVm.resetImport();
        importVm.setRestoreMode(BackupRestoreMode.replace);
        importVm.inspectBackupContent(
          fileName: 'backup.json',
          rawContent: exportedJson,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restore Backup'));
        await tester.pumpAndSettle();
        expect(find.text('Replace your data?'), findsOneWidget);
        await tester.tap(find.text('Replace Data'));
        await tester.pumpAndSettle();

        expect(find.text('Backup restored'), findsOneWidget);
        final replacedSubjects =
            await Get.find<SubjectRepository>().getSubjects();
        expect(replacedSubjects.map((s) => s.name).toList(), <String>['Algorithms']);

        // Replace wrote a safety copy of the pre-restore data first.
        final snapshotPath = backupService.lastSafetySnapshotPath;
        expect(snapshotPath, isNotNull);
        final snapshot = File(snapshotPath!).readAsStringSync();
        expect(snapshot, contains('Chemistry'));

        await _disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'ReportService & ExportReportView switch period dynamically and generate CSV + valid PDF bytes',
      (tester) async {
        final binding = InitialBinding(database: db);
        binding.dependencies();

        final subjId = await Get.find<SubjectRepository>().createSubject(
          name: 'Biology',
          identifier: SubjectIdentifier.circle,
          iconKey: SubjectIconKey.book,
          targetMinutes: 120,
        );
        final now = DateTime.now().toUtc();
        await _seedCompletedSession(
          sessionRepository: Get.find<SessionRepository>(),
          subjectId: subjId,
          mode: TimerMode.focus,
          startedAtMs: now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
          endedAtMs: now.millisecondsSinceEpoch,
          durationSeconds: 1500,
        );
        // Older session outside this week
        final lastYear = DateTime.utc(2025, 1, 10, 10);
        await _seedCompletedSession(
          sessionRepository: Get.find<SessionRepository>(),
          subjectId: subjId,
          mode: TimerMode.pomodoro,
          startedAtMs: lastYear.millisecondsSinceEpoch,
          endedAtMs: lastYear.add(const Duration(minutes: 50)).millisecondsSinceEpoch,
          durationSeconds: 3000,
        );

        String? sharedReportPath;
        final reportService = ReportService(
          sessionRepository: Get.find<SessionRepository>(),
          subjectRepository: Get.find<SubjectRepository>(),
          exportDirectoryProvider: () async => tempDir,
          shareFileHandler: (filePath, _) async {
            sharedReportPath = filePath;
          },
        );

        Get.put<ExportReportViewModel>(
          ExportReportViewModel(reportService: reportService),
        );

        await tester.pumpWidget(_buildHostApp(home: const ExportReportView()));
        await tester.pumpAndSettle();

        expect(find.text('Export Study Report'), findsOneWidget);
        expect(find.text('25m'), findsOneWidget);

        // Switch period to All time dynamically updates preview total to 1h 15m (75m).
        await tester.tap(find.text('All time'));
        await tester.pumpAndSettle();
        expect(find.text('1h 15m'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Export PDF report.
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Report'));
        await _waitForCondition(
          tester,
          () => !Get.find<ExportReportViewModel>().isExporting.value &&
              sharedReportPath != null,
        );
        await tester.pumpAndSettle();
        expect(sharedReportPath, endsWith('.pdf'));
        final pdfBytes =
            await tester.runAsync(() => File(sharedReportPath!).readAsBytes());
        expect(ascii.decode(pdfBytes!.take(4).toList()), '%PDF');
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Switch to CSV data & export CSV.
        await tester.tap(find.text('CSV data'));
        await tester.pump();
        final prevPath = sharedReportPath;
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Report'));
        await _waitForCondition(
          tester,
          () => !Get.find<ExportReportViewModel>().isExporting.value &&
              sharedReportPath != prevPath,
        );
        await tester.pumpAndSettle();
        expect(sharedReportPath, endsWith('.csv'));
        final csvText =
            await tester.runAsync(() => File(sharedReportPath!).readAsString());
        expect(csvText, contains('Biology'));

        await _disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'PrivacyPolicyView & NavigationFlowView render offline storage disclosures and routes without notifications',
      (tester) async {
        await tester.pumpWidget(_buildHostApp(home: const PrivacyPolicyView()));
        await tester.pump();
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.textContaining('Android Auto Backup'), findsOneWidget);

        await tester.pumpWidget(
          _buildHostApp(home: const NavigationFlowView()),
        );
        await tester.pump();
        expect(find.text('Navigation Flow'), findsOneWidget);
        expect(find.textContaining('Notification'), findsNothing);
        await tester.scrollUntilVisible(find.text('Export Backup'), 300);
        expect(find.text('Export Backup'), findsOneWidget);
      },
    );

    testWidgets(
      'BackupService save handler supports Save As download cancellation and confirmed UTF-8 JSON write',
      (tester) async {
        final binding = InitialBinding(database: db);
        binding.dependencies();

        await Get.find<SubjectRepository>().createSubject(
          name: 'Economics',
          identifier: SubjectIdentifier.ring,
          iconKey: SubjectIconKey.calculator,
          targetMinutes: 150,
        );

        String? nextSavedPath;
        String? savedFileName;
        List<int>? savedBytes;
        String? sharedCopyPath;

        final service = BackupService(
          database: db,
          goalStreakRepository: Get.find<GoalStreakRepository>(),
          settingsRepository: Get.find<SettingsRepository>(),
          achievementRepository: Get.find<AchievementRepository>(),
          exportDirectoryProvider: () async => tempDir,
          saveBackupFileHandler: (fileName, bytes) async {
            savedFileName = fileName;
            savedBytes = bytes;
            return nextSavedPath;
          },
          shareFileHandler: (filePath, _) async {
            sharedCopyPath = filePath;
          },
        );

        Get.put<BackupViewModel>(
          BackupViewModel(
            backupService: service,
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );

        await tester.pumpWidget(_buildHostApp(home: const ExportBackupView()));
        await tester.pumpAndSettle();

        // 1. User cancels system Save As dialog -> stays on preview, no fake success.
        nextSavedPath = null;
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Backup'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Backup').last);
        await _waitForCondition(
          tester,
          () => Get.find<BackupViewModel>().exportStage.value ==
              ExportBackupStage.preview,
        );
        await tester.pumpAndSettle();
        expect(find.text('Backup saved'), findsNothing);
        expect(find.text("What's included"), findsOneWidget);

        // 2. User confirms Save in Downloads -> writes valid JSON bytes & shows Saved screen.
        nextSavedPath =
            '/document/primary:Download/parhaimate-backup-2026-11-20.json';
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Backup'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PmPrimaryButton, 'Export Backup').last);
        await _waitForCondition(
          tester,
          () => Get.find<BackupViewModel>().exportStage.value ==
              ExportBackupStage.saved,
        );
        await tester.pumpAndSettle();

        expect(find.text('Backup saved'), findsOneWidget);
        expect(find.textContaining('Saved to Downloads'), findsOneWidget);
        expect(savedFileName, endsWith('.json'));
        final parsedSaved =
            jsonDecode(utf8.decode(savedBytes!)) as Map<String, dynamic>;
        expect((parsedSaved['subjects'] as List<dynamic>).first['name'], 'Economics');

        await tester.tap(find.text('Share File'));
        await tester.pump();
        expect(sharedCopyPath, isNotNull);

        await _disposeWidgetTree(tester);
      },
    );
  });
}
