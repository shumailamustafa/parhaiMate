import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../services/backup_service.dart';
import '../viewmodels/backup_viewmodel.dart';

/// Export Backup screen (Preview -> Confirmation -> Exporting -> Saved).
class ExportBackupView extends GetView<BackupViewModel> {
  const ExportBackupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PmAppBar(title: 'Export Backup'),
      body: Obx(() {
        final stage = controller.exportStage.value;
        final preview = controller.exportPreview.value;
        final exported = controller.exportedFile.value;

        switch (stage) {
          case ExportBackupStage.preview:
            return _ExportPreviewBody(
              preview: preview,
              onExportPressed: () => _confirmAndExport(context),
            );
          case ExportBackupStage.exporting:
            return const PmLoadingState(message: 'Creating backup file...');
          case ExportBackupStage.saved:
            return _ExportSavedBody(
              exportedFile: exported,
              onDone: () => Get.back<void>(),
              onShare: controller.shareExportedBackup,
            );
        }
      }),
    );
  }

  Future<void> _confirmAndExport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.file_download_outlined,
        title: 'Export backup?',
        message:
            'Your subjects, study sessions, planner tasks, goals, and timer presets will be saved into a local .json file.',
        confirmLabel: 'Export Backup',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed == true) {
      await controller.performExport();
      final error = controller.exportError.value;
      if (error != null && context.mounted) {
        PmToast.show(context, error);
      }
    }
  }
}

class _ExportPreviewBody extends StatelessWidget {
  const _ExportPreviewBody({
    required this.preview,
    required this.onExportPressed,
  });

  final BackupPreviewSummary? preview;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          "What's included",
                          style: AppTypography.section18,
                        ),
                        const SizedBox(height: 16),
                        _SummaryRow(
                          label: 'Subjects',
                          value: preview == null
                              ? '...'
                              : '${preview!.subjectsCount}',
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        _SummaryRow(
                          label: 'Study sessions',
                          value: preview == null
                              ? '...'
                              : '${preview!.sessionsCount}',
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        _SummaryRow(
                          label: 'Planner tasks',
                          value:
                              preview == null ? '...' : '${preview!.tasksCount}',
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        const _SummaryRow(
                          label: 'Goals & presets',
                          value: 'Included',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PmGreyCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Backup file',
                                style: AppTypography.secondary14SemiBold,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preview?.suggestedFileName ??
                                    'parhaimate-backup.json',
                                style: AppTypography.body16Medium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preview?.formattedSize ?? 'Calculating...',
                                style: AppTypography.meta12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PmPrimaryButton(
            label: 'Export Backup',
            onPressed: preview != null ? onExportPressed : null,
          ),
        ],
      ),
    );
  }
}

class _ExportSavedBody extends StatelessWidget {
  const _ExportSavedBody({
    required this.exportedFile,
    required this.onDone,
    required this.onShare,
  });

  final ExportedBackupFile? exportedFile;
  final VoidCallback onDone;
  final Future<void> Function() onShare;

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
            'Backup saved',
            style: AppTypography.title24,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            exportedFile == null
                ? 'Your offline backup file has been saved.'
                : '${exportedFile!.fileName}\nSaved to ${exportedFile!.locationLabel}',
            style: AppTypography.secondary14,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          PmPrimaryButton(label: 'Done', onPressed: onDone),
          const SizedBox(height: 12),
          PmSecondaryButton(
            label: 'Share File',
            icon: Icons.share_outlined,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: AppTypography.body16Medium),
        ),
        Text(value, style: AppTypography.secondary14SemiBold),
      ],
    );
  }
}
