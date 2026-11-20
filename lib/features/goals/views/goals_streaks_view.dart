import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../viewmodels/goals_viewmodel.dart';

/// Goals & Streaks screen matching 13 Goals & Streaks.png & Edited.png.
class GoalsStreaksView extends GetView<GoalsViewModel> {
  const GoalsStreaksView({super.key});

  static const List<String> _weekdayInitials = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Goals & Streaks'),
      body: Obx(() {
        final draftDaily = controller.draftDailyMinutes.value;
        final draftWeekly = controller.draftWeeklyMinutes.value;
        final dailyPct = controller.dailyProgressPercent;
        final dailyFraction = controller.dailyProgressFraction;
        final studiedToday = controller.todayStudiedMinutes;
        final remainingToday = controller.dailyRemainingMinutes;
        final weekStudied = controller.weekStudiedMinutes;
        final weekRemaining = controller.weeklyRemainingMinutes;
        final cells = controller.heatmapCells;
        final hasChanges = controller.hasUnsavedChanges;

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
                    PmGreyCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                      child: Row(
                        children: <Widget>[
                          PmCircularProgress(
                            size: 128,
                            strokeWidth: 11,
                            progress: dailyFraction,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '$dailyPct%',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'of daily goal',
                                  style: AppTypography.meta12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Daily target',
                                  style: AppTypography.meta12,
                                ),
                                Text(
                                  DateTimeUtils.formatMinutes(draftDaily),
                                  style: AppTypography.body16SemiBold,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Studied',
                                  style: AppTypography.meta12,
                                ),
                                Text(
                                  DateTimeUtils.formatMinutes(studiedToday),
                                  style: AppTypography.body16SemiBold,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Remaining',
                                  style: AppTypography.meta12,
                                ),
                                Text(
                                  DateTimeUtils.formatMinutes(remainingToday),
                                  style: AppTypography.body16SemiBold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const Text('Weekly Goal', style: AppTypography.section18),
                    const SizedBox(height: 12),
                    PmWhiteCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Weekly target ${DateTimeUtils.formatMinutes(draftWeekly)}',
                                  style: AppTypography.secondary14,
                                ),
                              ),
                              Text(
                                '$weekStudied of $draftWeekly min',
                                style: AppTypography.secondary14SemiBold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PmProgressBar(
                            progress: controller.weeklyProgressFraction,
                            height: 7,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${DateTimeUtils.formatMinutes(weekRemaining)} left · ${controller.daysRemainingInWeek} ${controller.daysRemainingInWeek == 1 ? 'day' : 'days'} to go',
                            style: AppTypography.secondary14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const Text('Streak', style: AppTypography.section18),
                    const SizedBox(height: 12),
                    PmWhiteCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                      child: IntrinsicHeight(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.local_fire_department_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Current streak',
                                        style: AppTypography.secondary14,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text.rich(
                                    TextSpan(
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: '${controller.currentStreak}',
                                          style: AppTypography.title24,
                                        ),
                                        const TextSpan(
                                          text: ' days',
                                          style: AppTypography.secondary14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(
                              width: 24,
                              thickness: 1,
                              color: AppColors.divider,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Longest streak',
                                    style: AppTypography.secondary14,
                                  ),
                                  const SizedBox(height: 8),
                                  Text.rich(
                                    TextSpan(
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: '${controller.longestStreak}',
                                          style: AppTypography.title24,
                                        ),
                                        const TextSpan(
                                          text: ' days',
                                          style: AppTypography.secondary14,
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
                    const SizedBox(height: 14),
                    PmWhiteCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const PmSectionHeader(
                            title: 'Weekly activity',
                            trailingMeta: 'Mon–Sun',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: _weekdayInitials
                                .map(
                                  (day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: AppTypography.meta12,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                          ...List<Widget>.generate(4, (weekIndex) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: weekIndex < 3 ? 8 : 0,
                              ),
                              child: Row(
                                children: List<Widget>.generate(7, (dayIndex) {
                                  final cell = cells[weekIndex * 7 + dayIndex];
                                  return Expanded(
                                    child: Center(
                                      child: _HeatmapSquare(cell: cell),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          const Row(
                            children: <Widget>[
                              _HeatmapLegendItem(
                                color: AppColors.primary,
                                label: 'Studied',
                              ),
                              SizedBox(width: 18),
                              _HeatmapLegendItem(
                                color: AppColors.surface,
                                label: 'Missed',
                              ),
                              SizedBox(width: 18),
                              _HeatmapLegendItem(
                                color: AppColors.card,
                                bordered: true,
                                label: 'Upcoming',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const Text('Goal Settings', style: AppTypography.section18),
                    const SizedBox(height: 12),
                    PmWhiteCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Daily study goal',
                                  style: AppTypography.body16SemiBold,
                                ),
                              ),
                              Text(
                                '${DateTimeUtils.formatMinutes(draftDaily)} a day',
                                style: AppTypography.secondary14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PmStepperField(
                            valueLabel: '$draftDaily min',
                            canDecrement:
                                draftDaily > GoalsViewModel.minDailyMinutes,
                            canIncrement:
                                draftDaily < GoalsViewModel.maxDailyMinutes,
                            onDecrement: () => controller.adjustDailyGoal(
                              -GoalsViewModel.dailyStepMinutes,
                            ),
                            onIncrement: () => controller.adjustDailyGoal(
                              GoalsViewModel.dailyStepMinutes,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Weekly study goal',
                                  style: AppTypography.body16SemiBold,
                                ),
                              ),
                              Text(
                                '${DateTimeUtils.formatMinutes(draftWeekly)} a week',
                                style: AppTypography.secondary14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PmStepperField(
                            valueLabel: '$draftWeekly min',
                            canDecrement:
                                draftWeekly > GoalsViewModel.minWeeklyMinutes,
                            canIncrement:
                                draftWeekly < GoalsViewModel.maxWeeklyMinutes,
                            onDecrement: () => controller.adjustWeeklyGoal(
                              -GoalsViewModel.weeklyStepMinutes,
                            ),
                            onIncrement: () => controller.adjustWeeklyGoal(
                              GoalsViewModel.weeklyStepMinutes,
                            ),
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
                  label: 'Save Changes',
                  isLoading: controller.isSaving.value,
                  onPressed: hasChanges
                      ? () async {
                          await controller.saveChanges();
                          if (context.mounted) {
                            PmToast.show(context, 'Study goals updated');
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

class _HeatmapSquare extends StatelessWidget {
  const _HeatmapSquare({required this.cell});

  final HeatmapDayCell cell;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    Border? border;

    switch (cell.state) {
      case HeatmapCellState.studied:
        bg = AppColors.primary;
        if (cell.isToday) {
          border = Border.all(color: AppColors.foreground, width: 1.8);
        }
      case HeatmapCellState.missed:
        bg = AppColors.surface;
      case HeatmapCellState.upcoming:
        bg = AppColors.card;
        border = Border.all(
          color: cell.isToday ? AppColors.foreground : AppColors.border,
          width: cell.isToday ? 1.8 : 1,
        );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
    );
  }
}

class _HeatmapLegendItem extends StatelessWidget {
  const _HeatmapLegendItem({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: bordered ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.meta12),
      ],
    );
  }
}
