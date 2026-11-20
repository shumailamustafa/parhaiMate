import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/enums/domain_enums.dart';
import '../services/backup_service.dart';
import '../viewmodels/backup_viewmodel.dart';

/// Import Backup screen (Choose File -> Error / Preview -> Restoring -> Restored).
class ImportBackupView extends GetView<BackupViewModel> {
  const ImportBackupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PmAppBar(title: 'Import Backup'),
      body: Obx(() {
        final stage = controller.importStage.value;
        final failure = controller.parseFailure.value;
        final parsed = controller.parsedBackup.value;
        final restoreMode = controller.restoreMode.value;

        switch (stage) {
          case ImportBackupStage.chooseFile:
            return _ChooseFileBody(onBrowsePressed: controller.chooseBackupFile);
          case ImportBackupStage.error:
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Center(
                child: PmErrorState(
                  title: failure?.title ?? "Couldn't read this file",
                  message: failure?.message ??
                      'Select a valid ParhaiMate .json backup file.',
                  retryLabel: 'Choose Another File',
                  onRetry: controller.resetImport,
                ),
              ),
            );
          case ImportBackupStage.preview:
            if (parsed == null) {
              return _ChooseFileBody(
                onBrowsePressed: controller.chooseBackupFile,
              );
            }
            return _ImportPreviewBody(
              document: parsed,
              restoreMode: restoreMode,
              onSelectMode: controller.setRestoreMode,
              onRestorePressed: () =>
                  _confirmAndRestore(context, restoreMode),
              onChooseAnother: controller.resetImport,
            );
          case ImportBackupStage.restoring:
            return const PmLoadingState(message: 'Restoring backup data...');
          case ImportBackupStage.restored:
            return _RestoredBody(onDone: () => Get.back<void>());
        }
      }),
    );
  }

  Future<void> _confirmAndRestore(
    BuildContext context,
    BackupRestoreMode mode,
  ) async {
    if (mode == BackupRestoreMode.replace) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => PmConfirmationDialog(
          icon: Icons.warning_amber_rounded,
          title: 'Replace your data?',
          message:
              'All existing subjects, study sessions, tasks, goals, and timer presets will be replaced by this backup.',
          confirmLabel: 'Replace Data',
          isDestructive: true,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    await controller.executeRestore();
  }
}

class _ChooseFileBody extends StatelessWidget {
  const _ChooseFileBody({required this.onBrowsePressed});

  final Future<void> Function() onBrowsePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Center(
        child: PmWhiteCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose a backup file',
                  style: AppTypography.section18,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'ParhaiMate .json backups only',
                  style: AppTypography.secondary14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PmPrimaryButton(
                  label: 'Browse Files',
                  fullWidth: false,
                  size: PmButtonSize.medium,
                  onPressed: onBrowsePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportPreviewBody extends StatelessWidget {
  const _ImportPreviewBody({
    required this.document,
    required this.restoreMode,
    required this.onSelectMode,
    required this.onRestorePressed,
    required this.onChooseAnother,
  });

  final ParsedBackupDocument document;
  final BackupRestoreMode restoreMode;
  final ValueChanged<BackupRestoreMode> onSelectMode;
  final VoidCallback onRestorePressed;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final exportedDate = document.exportedAtDate;
    final dateText = exportedDate != null
        ? 'Created ${DateTimeUtils.formatShortDate(exportedDate)}'
        : 'Backup v${document.schemaVersion}';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PmWhiteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    document.fileName,
                                    style: AppTypography.body16SemiBold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(dateText, style: AppTypography.meta12),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        _CountRow(
                          label: 'Subjects',
                          count: document.subjects.length,
                        ),
                        const SizedBox(height: 10),
                        _CountRow(
                          label: 'Sessions',
                          count: document.sessions.length,
                        ),
                        const SizedBox(height: 10),
                        _CountRow(
                          label: 'Tasks',
                          count: document.tasks.length,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Restore options', style: AppTypography.section18),
                  const SizedBox(height: 12),
                  _RestoreOptionCard(
                    title: 'Replace current data',
                    subtitle:
                        'Replaces your current subjects, sessions, tasks, goals, and presets.',
                    selected: restoreMode == BackupRestoreMode.replace,
                    onTap: () => onSelectMode(BackupRestoreMode.replace),
                  ),
                  const SizedBox(height: 10),
                  _RestoreOptionCard(
                    title: 'Merge with current data',
                    subtitle:
                        'Keeps existing records and adds non-duplicate items from backup.',
                    selected: restoreMode == BackupRestoreMode.merge,
                    onTap: () => onSelectMode(BackupRestoreMode.merge),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PmPrimaryButton(
            label: 'Restore Backup',
            onPressed: onRestorePressed,
          ),
          const SizedBox(height: 8),
          Center(
            child: PmGhostButton(
              label: 'Choose Another File',
              onPressed: onChooseAnother,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoredBody extends StatelessWidget {
  const _RestoredBody({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: <Widget>[
          const Spacer(),
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.onPrimary,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Backup restored',
            style: AppTypography.title24,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your study data is ready',
            style: AppTypography.secondary14,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          PmPrimaryButton(label: 'Done', onPressed: onDone),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTypography.body16Medium)),
        Text('$count', style: AppTypography.secondary14SemiBold),
      ],
    );
  }
}

class _RestoreOptionCard extends StatelessWidget {
  const _RestoreOptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardRadius,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.body16SemiBold),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTypography.secondary14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
