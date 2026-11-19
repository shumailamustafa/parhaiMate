import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/session_setup_viewmodel.dart';
import '../widgets/timer_pickers.dart';

/// Session Setup screen matching 05 Session Setup.png and mode variants.
class SessionSetupView extends GetView<SessionSetupViewModel> {
  const SessionSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Set Up Your Session'),
      body: Obx(() {
        final mode = controller.selectedMode.value;
        final subject = controller.selectedSubject;
        final duration = controller.focusMinutes.value;
        final shortBreak = controller.shortBreakMinutes.value;
        final longBreak = controller.longBreakMinutes.value;
        final cycles = controller.totalCycles.value;
        final isCustom = !controller.isPresetDuration(duration);

        return Column(
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
                          value: TimerMode.stopwatch,
                          label: 'Stopwatch',
                        ),
                        PmSegmentOption<TimerMode>(
                          value: TimerMode.pomodoro,
                          label: 'Pomodoro',
                        ),
                      ],
                    ),
                    if (mode != TimerMode.stopwatch) ...<Widget>[
                      const SizedBox(height: 22),
                      const Text(
                        'Duration',
                        style: AppTypography.secondary14SemiBold,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          ...SessionSetupViewModel.durationChoices.map(
                            (minutes) => PmChip(
                              label: '$minutes min',
                              selected: !isCustom && duration == minutes,
                              onTap: () => controller.selectDuration(minutes),
                            ),
                          ),
                          PmChip(
                            label: isCustom
                                ? 'Custom ($duration min)'
                                : 'Custom',
                            selected: isCustom,
                            onTap: () => showCustomDurationSheet(
                              context: context,
                              initialMinutes: duration,
                              onApply: controller.selectDuration,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (mode == TimerMode.pomodoro) ...<Widget>[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 18),
                      const Text(
                        'Pomodoro settings',
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 14),
                      PmStepperField(
                        label: 'Focus duration',
                        valueLabel: '$duration min',
                        canDecrement: duration > 5,
                        canIncrement: duration < 180,
                        onDecrement: () => controller.adjustFocusMinutes(-5),
                        onIncrement: () => controller.adjustFocusMinutes(5),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: PmStepperField(
                              label: 'Short break',
                              valueLabel: '$shortBreak min',
                              canDecrement: shortBreak > 1,
                              canIncrement: shortBreak < 30,
                              onDecrement: () =>
                                  controller.adjustShortBreakMinutes(-1),
                              onIncrement: () =>
                                  controller.adjustShortBreakMinutes(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PmStepperField(
                              label: 'Long break',
                              valueLabel: '$longBreak min',
                              canDecrement: longBreak > 5,
                              canIncrement: longBreak < 60,
                              onDecrement: () =>
                                  controller.adjustLongBreakMinutes(-5),
                              onIncrement: () =>
                                  controller.adjustLongBreakMinutes(5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                    PmTextArea(
                      label: 'Session notes (optional)',
                      hintText: 'Add a note for this session',
                      controller: controller.notesController,
                    ),
                    const SizedBox(height: 20),
                    PmGreyCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Session summary',
                            style: AppTypography.body16SemiBold,
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(
                            label: 'Subject',
                            value: controller.subjectSummaryLabel,
                          ),
                          const Divider(height: 22, color: AppColors.track),
                          _SummaryRow(
                            label: 'Mode',
                            value: controller.modeSummaryLabel,
                          ),
                          const Divider(height: 22, color: AppColors.track),
                          _SummaryRow(
                            label: 'Planned time',
                            value: controller.plannedTimeLabel,
                          ),
                          const Divider(height: 22, color: AppColors.track),
                          _SummaryRow(
                            label: 'Ends at',
                            value: controller.endsAtLabel,
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
                  label: 'Start Session',
                  isLoading: controller.isStarting.value,
                  onPressed: controller.startSession,
                ),
              ),
            ),
          ],
        );
      }),
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
        Expanded(child: Text(label, style: AppTypography.secondary14)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: AppTypography.secondary14SemiBold,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
