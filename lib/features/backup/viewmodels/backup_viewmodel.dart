import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/timer_engine_service.dart';
import '../../../domain/enums/domain_enums.dart';
import '../services/backup_service.dart';

enum ExportBackupStage { preview, exporting, saved }

enum ImportBackupStage { chooseFile, preview, error, restoring, restored }

/// ViewModel backing Export Backup, Import Backup, and Study Report flows.
class BackupViewModel extends GetxController {
  BackupViewModel({
    required BackupService backupService,
    required TimerEngineService timerEngine,
  })  : _backupService = backupService,
        _timerEngine = timerEngine;

  final BackupService _backupService;
  final TimerEngineService _timerEngine;

  // Export state
  final Rx<ExportBackupStage> exportStage = ExportBackupStage.preview.obs;
  final Rxn<BackupPreviewSummary> exportPreview = Rxn<BackupPreviewSummary>();
  final Rxn<ExportedBackupFile> exportedFile = Rxn<ExportedBackupFile>();
  final RxnString exportError = RxnString();

  // Import state
  final Rx<ImportBackupStage> importStage = ImportBackupStage.chooseFile.obs;
  final Rxn<ParsedBackupDocument> parsedBackup = Rxn<ParsedBackupDocument>();
  final Rxn<BackupParseFailure> parseFailure = Rxn<BackupParseFailure>();
  final Rx<BackupRestoreMode> restoreMode = BackupRestoreMode.replace.obs;

  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadExportPreview());
  }

  Future<void> loadExportPreview() async {
    final preview = await _backupService.getExportPreview();
    if (!_disposed) {
      exportPreview.value = preview;
    }
  }

  Future<bool> performExport() async {
    exportError.value = null;
    exportStage.value = ExportBackupStage.exporting;
    try {
      final result = await _backupService.exportBackupToFile();
      if (_disposed) {
        return false;
      }
      if (result == null) {
        exportStage.value = ExportBackupStage.preview;
        return false;
      }
      exportedFile.value = result;
      exportStage.value = ExportBackupStage.saved;
      return true;
    } catch (_) {
      if (!_disposed) {
        exportError.value = 'Could not save backup file. Please try again.';
        exportStage.value = ExportBackupStage.preview;
      }
      return false;
    }
  }

  Future<void> shareExportedBackup() async {
    final file = exportedFile.value;
    if (file == null) {
      return;
    }
    await _backupService.shareBackupFile(file);
  }

  Future<void> chooseBackupFile() async {
    final picked = await _backupService.pickBackupFile();
    if (picked == null || _disposed) {
      return;
    }
    inspectBackupContent(fileName: picked.name, rawContent: picked.content);
  }

  void inspectBackupContent({
    required String fileName,
    required String rawContent,
  }) {
    final result = _backupService.validateAndParse(
      rawContent,
      fileName: fileName,
    );
    if (result.isSuccess) {
      parsedBackup.value = result.document;
      parseFailure.value = null;
      importStage.value = ImportBackupStage.preview;
    } else {
      parsedBackup.value = null;
      parseFailure.value = result.failure;
      importStage.value = ImportBackupStage.error;
    }
  }

  void setRestoreMode(BackupRestoreMode mode) {
    restoreMode.value = mode;
  }

  void resetImport() {
    parsedBackup.value = null;
    parseFailure.value = null;
    importStage.value = ImportBackupStage.chooseFile;
  }

  Future<void> executeRestore() async {
    final doc = parsedBackup.value;
    if (doc == null) {
      return;
    }
    importStage.value = ImportBackupStage.restoring;
    try {
      if (restoreMode.value == BackupRestoreMode.replace &&
          _timerEngine.hasActiveSession) {
        await _timerEngine.cancelSession();
      }
      await _backupService.restoreBackup(doc, restoreMode.value);
      await loadExportPreview();
      if (!_disposed) {
        importStage.value = ImportBackupStage.restored;
      }
    } catch (_) {
      if (!_disposed) {
        parseFailure.value = BackupParseFailure(
          title: 'This backup is damaged',
          message:
              'Some data in ${doc.fileName} is missing. Try a newer backup file.',
        );
        importStage.value = ImportBackupStage.error;
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }
}
