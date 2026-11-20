import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/enums/subject_visuals.dart';
import '../viewmodels/presets_viewmodel.dart';

/// Timer Presets Management screen matching Timer Preset Management.png & Empty.png.
class PresetsListView extends GetView<PresetsViewModel> {
  const PresetsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PmAppBar(
        title: 'Timer Presets',
        actions: <Widget>[
          IconButton(
            tooltip: 'Add Preset',
            icon: const Icon(
              Icons.add_rounded,
              size: 24,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Get.toNamed<void>(AppRoutes.createPreset),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.presets.isEmpty) {
          return const PmLoadingState(message: 'Loading presets...');
        }

        final list = controller.presets;
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: PmEmptyState(
              icon: Icons.add_rounded,
              title: 'No timer presets',
              subtitle: 'Save your favourite timer setups to start faster',
              actionLabel: 'Add Preset',
              actionIcon: Icons.add_rounded,
              onAction: () => Get.toNamed<void>(AppRoutes.createPreset),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            12,
            AppSpacing.screenPadding,
            28,
          ),
          child: PmWhiteCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List<Widget>.generate(list.length, (index) {
                final preset = list[index];
                return Column(
                  children: <Widget>[
                    InkWell(
                      onTap: () => Get.toNamed<void>(
                        AppRoutes.editPreset,
                        arguments: preset.id,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                preset.timerMode.iconData,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    preset.name,
                                    style: AppTypography.body16SemiBold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.subtitleForPreset(preset),
                                    style: AppTypography.secondary14,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            PmSecondaryButton(
                              label: 'Use',
                              size: PmButtonSize.small,
                              fullWidth: false,
                              onPressed: () => controller.usePreset(preset),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < list.length - 1)
                      const Divider(height: 1, color: AppColors.divider),
                  ],
                );
              }),
            ),
          ),
        );
      }),
    );
  }
}

/// Create / Edit Timer Preset screen matching New Preset / Edit Preset & Error.png.
class PresetFormView extends GetView<PresetFormViewModel> {
  const PresetFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing;
      final current = controller.editingPreset.value;
      final mode = controller.selectedMode.value;
      final focusMin = controller.focusMinutes.value;
      final shortMin = controller.shortBreakMinutes.value;
      final longMin = controller.longBreakMinutes.value;
      final cycles = controller.cyclesBeforeLongBreak.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(
          title: isEditing ? 'Edit Preset' : 'New Preset',
          actions: isEditing && current != null
              ? <Widget>[
                  IconButton(
                    tooltip: 'Delete Preset',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () =>
                        _showDeletePresetDialog(context, current.name),
                  ),
                ]
              : null,
        ),
        body: controller.isLoading.value
            ? const PmLoadingState(message: 'Loading preset...')
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        12,
                        AppSpacing.screenPadding,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          PmTextField(
                            label: 'Preset name',
                            hintText: 'Name your preset',
                            controller: controller.nameController,
                            errorText: controller.nameError.value,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Timer mode',
                            style: AppTypography.secondary14SemiBold,
                          ),
                          const SizedBox(height: 8),
                          PmSegmentedControl<TimerMode>(
                            selectedValue: mode,
                            onChanged: controller.selectMode,
                            options: const <PmSegmentOption<TimerMode>>[
                              PmSegmentOption<TimerMode>(
                                value: TimerMode.focus,
                                label: 'Focus Timer',
                              ),
                              PmSegmentOption<TimerMode>(
                                value: TimerMode.pomodoro,
                                label: 'Pomodoro',
                              ),
                              PmSegmentOption<TimerMode>(
                                value: TimerMode.stopwatch,
                                label: 'Stopwatch',
                              ),
                            ],
                          ),
                          if (mode != TimerMode.stopwatch) ...<Widget>[
                            const SizedBox(height: 20),
                            PmStepperField(
                              label: 'Focus duration',
                              valueLabel: '$focusMin min',
                              canDecrement: focusMin > 5,
                              canIncrement: focusMin < 180,
                              onDecrement: () => controller.adjustFocus(-5),
                              onIncrement: () => controller.adjustFocus(5),
                            ),
                          ],
                          if (mode == TimerMode.pomodoro) ...<Widget>[
                            const SizedBox(height: 16),
                            PmStepperField(
                              label: 'Short break',
                              valueLabel: '$shortMin min',
                              canDecrement: shortMin > 1,
                              canIncrement: shortMin < 30,
                              onDecrement: () =>
                                  controller.adjustShortBreak(-1),
                              onIncrement: () => controller.adjustShortBreak(1),
                            ),
                            const SizedBox(height: 16),
                            PmStepperField(
                              label: 'Long break',
                              valueLabel: '$longMin min',
                              canDecrement: longMin > 5,
                              canIncrement: longMin < 60,
                              onDecrement: () => controller.adjustLongBreak(-5),
                              onIncrement: () => controller.adjustLongBreak(5),
                            ),
                            const SizedBox(height: 16),
                            PmStepperField(
                              label: 'Cycles before long break',
                              valueLabel: '$cycles cycles',
                              canDecrement: cycles > 1,
                              canIncrement: cycles < 8,
                              onDecrement: () => controller.adjustCycles(-1),
                              onIncrement: () => controller.adjustCycles(1),
                            ),
                          ],
                          const SizedBox(height: 20),
                          PmGreyCard(
                            padding: const EdgeInsets.all(
                              AppSpacing.cardPaddingLarge,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Full session duration',
                                  style: AppTypography.secondary14,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.fullSessionSummaryLabel,
                                  style: AppTypography.title24,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        10,
                        AppSpacing.screenPadding,
                        16,
                      ),
                      child: PmPrimaryButton(
                        label: 'Save Preset',
                        isLoading: controller.isSaving.value,
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final saved = await controller.savePreset();
                          if (saved && context.mounted) {
                            navigator.pop(true);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Future<void> _showDeletePresetDialog(
    BuildContext context,
    String presetName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete $presetName?',
        message: "This preset will be removed. Your past sessions aren't affected.",
        confirmLabel: 'Delete Preset',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      final navigator = Navigator.of(context);
      await controller.deletePreset();
      if (context.mounted) {
        navigator.pop(true);
      }
    }
  }
}
