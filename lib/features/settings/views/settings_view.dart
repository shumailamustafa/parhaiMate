import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/widgets/parhaimate_logo.dart';
import '../viewmodels/settings_viewmodel.dart';

/// Settings screen matching 15 Settings.png (notification entry omitted).
class SettingsView extends GetView<SettingsViewModel> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Settings'),
      body: Obx(() {
        final dailyLabel =
            DateTimeUtils.formatMinutes(controller.dailyGoalMinutes.value);
        final weeklyLabel =
            DateTimeUtils.formatMinutes(controller.weeklyGoalMinutes.value);
        final defaultMode = controller.defaultTimerMode.value;
        final presetsCount = controller.presetsCount.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            12,
            AppSpacing.screenPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SettingsGroupLabel('General'),
              const SizedBox(height: 8),
              PmWhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    PmListTileRow(
                      title: 'Daily Study Goal',
                      trailingValue: dailyLabel,
                      leading: const Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () async {
                        await Get.toNamed<void>(AppRoutes.dailyGoalConfig);
                        await controller.refreshSettings();
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Weekly Study Goal',
                      trailingValue: weeklyLabel,
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () async {
                        await Get.toNamed<void>(AppRoutes.weeklyGoalConfig);
                        await controller.refreshSettings();
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Default Timer Mode',
                      trailingValue: defaultMode.label,
                      leading: const Icon(
                        Icons.replay_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () =>
                          _showDefaultModeSheet(context, defaultMode),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Timer Presets',
                      trailingValue:
                          '$presetsCount ${presetsCount == 1 ? 'preset' : 'presets'}',
                      leading: const Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.timerPresets),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsGroupLabel('Data & backup'),
              const SizedBox(height: 8),
              PmWhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    PmListTileRow(
                      title: 'Export Backup',
                      leading: const Icon(
                        Icons.file_download_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.exportBackup),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Import Backup',
                      leading: const Icon(
                        Icons.file_upload_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () async {
                        await Get.toNamed<void>(AppRoutes.importBackup);
                        await controller.refreshSettings();
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Export Study Report',
                      leading: const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.studyReport),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsGroupLabel('App information'),
              const SizedBox(height: 8),
              PmWhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    PmListTileRow(
                      title: 'About ParhaiMate',
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => _showAboutSheet(context),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Privacy Policy',
                      leading: const Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.privacyPolicy),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    const PmListTileRow(
                      title: 'App Version',
                      trailingValue: '1.0.0',
                      showChevron: false,
                      leading: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsGroupLabel('Data management'),
              const SizedBox(height: 8),
              PmWhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    PmListTileRow(
                      title: 'Clear Study History',
                      subtitle: 'Removes all sessions; subjects and tasks stay',
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => _showClearHistoryDialog(context),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Delete All App Data',
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => _showDeleteAllDataDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Center(child: PoweredByCodingDistrict()),
              const SizedBox(height: 8),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showDefaultModeSheet(
    BuildContext context,
    TimerMode currentMode,
  ) {
    return PmBottomSheet.show<void>(
      context: context,
      title: 'Default Timer Mode',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: TimerMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return Column(
            children: <Widget>[
              InkWell(
                borderRadius: AppRadii.controlRadius,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await controller.setDefaultTimerMode(mode);
                  if (context.mounted) {
                    navigator.pop();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          mode.label,
                          style: AppTypography.body16Medium,
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 22,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (mode != TimerMode.values.last)
                const Divider(height: 1, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showAboutSheet(BuildContext context) {
    return PmBottomSheet.show<void>(
      context: context,
      title: 'About ParhaiMate',
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 8),
          ParhaiMateLogo(size: 76),
          SizedBox(height: 16),
          Text('ParhaiMate', style: AppTypography.title24),
          SizedBox(height: 4),
          Text(
            'Your Personal Study Companion',
            style: AppTypography.secondary14,
          ),
          SizedBox(height: 6),
          Text('Version 1.0.0', style: AppTypography.meta12),
          SizedBox(height: 20),
          PoweredByCodingDistrict(),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final count = controller.sessionsCount.value;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Clear study history?',
        message:
            "All $count study sessions will be deleted. Your subjects, tasks and goals stay. You can't undo this.",
        confirmLabel: 'Clear History',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await controller.clearStudyHistory();
      if (context.mounted) {
        PmToast.show(context, 'Study history cleared');
      }
    }
  }

  Future<void> _showDeleteAllDataDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => const _DeleteAllDataDialog(),
    );
    if (confirmed ?? false) {
      await controller.deleteAllAppData();
    }
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.secondary14SemiBold.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DeleteAllDataDialog extends StatefulWidget {
  const _DeleteAllDataDialog();

  @override
  State<_DeleteAllDataDialog> createState() => _DeleteAllDataDialogState();
}

class _DeleteAllDataDialogState extends State<_DeleteAllDataDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _matchesDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      final matches = _confirmController.text.trim() == 'DELETE';
      if (matches != _matchesDelete) {
        setState(() => _matchesDelete = matches);
      }
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PmConfirmationDialog(
      icon: Icons.delete_outline_rounded,
      title: 'Delete all app data?',
      message:
          "Subjects, sessions, tasks and goals will be deleted from this device. Export a backup first if you want to keep them. You can't undo this.",
      confirmLabel: 'Delete Everything',
      isDestructive: true,
      confirmEnabled: _matchesDelete,
      bodyExtra: PmTextField(
        label: 'Type DELETE to confirm',
        hintText: 'DELETE',
        controller: _confirmController,
      ),
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
