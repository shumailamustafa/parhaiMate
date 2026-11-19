import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/study_timer_viewmodel.dart';
import '../widgets/timer_pickers.dart';

/// Study Timer tab view matching 04 Study Timer.png.
///
/// Subject selection is optional: users may start Focus Timer, Stopwatch, or
/// Pomodoro sessions immediately or assign a subject.
class StudyTimerView extends GetView<StudyTimerViewModel> {
  const StudyTimerView({super.key, this.showTitleHeader = true});

  final bool showTitleHeader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        final mode = controller.selectedMode.value;
        final subject = controller.selectedSubject;
        final duration = controller.focusMinutes.value;
        final shortBreak = controller.shortBreakMinutes.value;
        final isCustom = !controller.isPresetDuration(duration);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            16,
            AppSpacing.screenPadding,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showTitleHeader) ...<Widget>[
                const Text('Study Timer', style: AppTypography.title24),
                const SizedBox(height: 4),
              ],
              const Text(
                'Choose your focus mode',
                style: AppTypography.secondary14,
              ),
              const SizedBox(height: 18),
              TimerModeCard(
                mode: TimerMode.focus,
                metaText: '$duration min',
                description: 'Stay focused for a set amount of time.',
                selected: mode == TimerMode.focus,
                onTap: () => controller.selectMode(TimerMode.focus),
              ),
              const SizedBox(height: 12),
              TimerModeCard(
                mode: TimerMode.stopwatch,
                metaText: 'No limit',
                description: 'Track your study time freely.',
                selected: mode == TimerMode.stopwatch,
                onTap: () => controller.selectMode(TimerMode.stopwatch),
              ),
              const SizedBox(height: 12),
              TimerModeCard(
                mode: TimerMode.pomodoro,
                metaText: '$duration + $shortBreak min',
                description: 'Study smarter with structured intervals.',
                selected: mode == TimerMode.pomodoro,
                onTap: () => controller.selectMode(TimerMode.pomodoro),
              ),
              const SizedBox(height: 22),
              PmDropdownField(
                label: 'Select Subject (optional)',
                placeholder: 'Choose a subject',
                valueText: subject?.name,
                leading: subject != null
                    ? SubjectIconBox(
                        iconKey: subject.iconKey,
                        size: 32,
                        iconSize: 16,
                      )
                    : null,
                onTap: () => showSubjectPickerSheet(
                  context: context,
                  subjects: controller.subjects,
                  selectedSubjectId: controller.selectedSubjectId.value,
                  onSelected: controller.selectSubject,
                ),
              ),
              if (mode != TimerMode.stopwatch) ...<Widget>[
                const SizedBox(height: 22),
                const Text(
                  'Select Duration',
                  style: AppTypography.secondary14SemiBold,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ...StudyTimerViewModel.durationChoices.map(
                      (minutes) => PmChip(
                        label: '$minutes min',
                        selected: !isCustom && duration == minutes,
                        onTap: () => controller.selectDuration(minutes),
                      ),
                    ),
                    PmChip(
                      label: isCustom ? 'Custom ($duration min)' : 'Custom',
                      selected: isCustom,
                      onTap: () => showCustomDurationSheet(
                        context: context,
                        initialMinutes: duration,
                        onApply: controller.selectDuration,
                      ),
                    ),
                  ],
                ),
                if (mode == TimerMode.pomodoro) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '$shortBreak min short break after each focus block',
                    style: AppTypography.secondary14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              PmPrimaryButton(
                label: 'Start Studying',
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.sessionSetup,
                  arguments: controller.buildSessionSetupArgs(),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: PmGhostButton(
                  label: 'Manage Timer Presets',
                  onPressed: () => Get.toNamed<void>(AppRoutes.timerPresets),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
