import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../viewmodels/goal_config_viewmodel.dart';

/// Daily Study Goal screen matching Daily Goal Configuration.png.
class DailyGoalConfigView extends GetView<GoalConfigViewModel> {
  const DailyGoalConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Daily Study Goal'),
      body: Obx(() {
        final draft = controller.draftDailyMinutes.value;
        final hasChanges = controller.hasDailyChanges;

        return Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  24,
                  AppSpacing.screenPadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        PmIconButton(
                          icon: Icons.remove_rounded,
                          size: 52,
                          tooltip: 'Decrease goal',
                          onPressed: draft > GoalConfigViewModel.minDailyMinutes
                              ? () => controller.adjustDailyMinutes(
                                    -GoalConfigViewModel.dailyStep,
                                  )
                              : null,
                        ),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: 112,
                          child: Text(
                            DateTimeUtils.formatMinutes(draft),
                            textAlign: TextAlign.center,
                            style: AppTypography.display32,
                          ),
                        ),
                        const SizedBox(width: 28),
                        PmIconButton(
                          icon: Icons.add_rounded,
                          size: 52,
                          tooltip: 'Increase goal',
                          onPressed: draft < GoalConfigViewModel.maxDailyMinutes
                              ? () => controller.adjustDailyMinutes(
                                    GoalConfigViewModel.dailyStep,
                                  )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: GoalConfigViewModel.dailyPresetHours.map((h) {
                          final mins = h * 60;
                          return PmChip(
                            label: '${h}h',
                            selected: draft == mins,
                            onTap: () => controller.setDailyMinutes(mins),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PmGreyCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Text(
                        controller.dailySummaryBanner,
                        textAlign: TextAlign.center,
                        style: AppTypography.secondary14,
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
                  label: 'Save Goal',
                  isLoading: controller.isSaving.value,
                  onPressed: hasChanges
                      ? () async {
                          final navigator = Navigator.of(context);
                          await controller.saveDailyGoal();
                          if (context.mounted) {
                            navigator.pop(true);
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Weekly Study Goal screen matching Weekly Goal Configuration.png.
class WeeklyGoalConfigView extends GetView<GoalConfigViewModel> {
  const WeeklyGoalConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Weekly Study Goal'),
      body: Obx(() {
        final draft = controller.draftWeeklyMinutes.value;
        final hasChanges = controller.hasWeeklyChanges;

        return Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  24,
                  AppSpacing.screenPadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        PmIconButton(
                          icon: Icons.remove_rounded,
                          size: 52,
                          tooltip: 'Decrease weekly goal',
                          onPressed:
                              draft > GoalConfigViewModel.minWeeklyMinutes
                                  ? () => controller.adjustWeeklyMinutes(
                                        -GoalConfigViewModel.weeklyStep,
                                      )
                                  : null,
                        ),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: 112,
                          child: Text(
                            DateTimeUtils.formatMinutes(draft),
                            textAlign: TextAlign.center,
                            style: AppTypography.display32,
                          ),
                        ),
                        const SizedBox(width: 28),
                        PmIconButton(
                          icon: Icons.add_rounded,
                          size: 52,
                          tooltip: 'Increase weekly goal',
                          onPressed:
                              draft < GoalConfigViewModel.maxWeeklyMinutes
                                  ? () => controller.adjustWeeklyMinutes(
                                        GoalConfigViewModel.weeklyStep,
                                      )
                                  : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children:
                            GoalConfigViewModel.weeklyPresetHours.map((h) {
                          final mins = h * 60;
                          return PmChip(
                            label: '${h}h',
                            selected: draft == mins,
                            onTap: () => controller.setWeeklyMinutes(mins),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PmGreyCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            controller.weeklyDailyAverageLabel,
                            textAlign: TextAlign.center,
                            style: AppTypography.secondary14,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.weeklyStudiedBanner,
                            textAlign: TextAlign.center,
                            style: AppTypography.secondary14SemiBold,
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
                  label: 'Save Goal',
                  isLoading: controller.isSaving.value,
                  onPressed: hasChanges
                      ? () async {
                          final navigator = Navigator.of(context);
                          await controller.saveWeeklyGoal();
                          if (context.mounted) {
                            navigator.pop(true);
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
