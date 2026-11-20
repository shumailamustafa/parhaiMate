import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/statistics_viewmodel.dart';

/// Statistics screen (Progress tab) matching 12 Statistics.png & variants.
class StatisticsView extends GetView<StatisticsViewModel> {
  const StatisticsView({super.key, this.showTitleHeader = true});

  final bool showTitleHeader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        final period = controller.selectedPeriod.value;
        final totalMin = controller.totalMinutes;
        final sessionsCount = controller.sessionsCount;
        final avgDailyMin = controller.averageDailyMinutes;
        final longestMin = controller.longestSessionMinutes;
        final hasActivity = sessionsCount > 0;
        final buckets = controller.barBuckets;
        final slices = controller.subjectSlices;
        final activity = controller.dailyActivityPoints;
        final dailyGoal = controller.dailyGoalMinutes.value;
        final topSubject = controller.mostStudiedSubject;

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
                const Text('Statistics', style: AppTypography.title24),
                const SizedBox(height: 14),
              ],
              PmSegmentedControl<StatsPeriod>(
                selectedValue: period,
                onChanged: controller.setPeriod,
                options: StatsPeriod.values
                    .map(
                      (p) => PmSegmentOption<StatsPeriod>(
                        value: p,
                        label: p.label,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              PmSectionHeader(
                title: 'Overview',
                trailingMeta: controller.periodMetaLabel,
              ),
              const SizedBox(height: 12),
              PmGreyCard(
                padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Total Study Time',
                      style: AppTypography.secondary14,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeUtils.formatMinutes(totalMin),
                      style: AppTypography.display32,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          controller.isComparisonGain
                              ? Icons.north_east_rounded
                              : Icons.south_east_rounded,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            controller.comparisonLabel,
                            style: AppTypography.secondary14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PmWhiteCard(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: IntrinsicHeight(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _OverviewStatCell(
                          label: 'Total Sessions',
                          value: '$sessionsCount',
                        ),
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _OverviewStatCell(
                          label: 'Average Daily\nStudy Time',
                          value: DateTimeUtils.formatMinutes(avgDailyMin),
                        ),
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _OverviewStatCell(
                          label: 'Longest\nSession',
                          value: DateTimeUtils.formatMinutes(longestMin),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (!hasActivity)
                const PmEmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No study activity yet',
                  subtitle: 'Finish a study session to see your statistics',
                )
              else ...<Widget>[
                PmSectionHeader(
                  title: controller.barChartTitle,
                  trailingMeta: controller.periodMetaLabel,
                ),
                const SizedBox(height: 12),
                _PeriodBarChartCard(period: period, buckets: buckets),
                const SizedBox(height: AppSpacing.sectionGap),
                PmSectionHeader(
                  title: 'Subject Distribution',
                  trailingMeta: controller.periodMetaLabel,
                ),
                const SizedBox(height: 12),
                _SubjectDistributionCard(
                  totalLabel: DateTimeUtils.formatMinutes(totalMin),
                  slices: slices,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PmSectionHeader(
                  title: 'Daily Study Activity',
                  trailingMeta: 'Last ${controller.activityWindowDays} days',
                ),
                const SizedBox(height: 12),
                _DailyActivityLineCard(
                  points: activity,
                  dailyGoalMinutes: dailyGoal,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Text('Insights', style: AppTypography.section18),
                const SizedBox(height: 12),
                PmWhiteCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (topSubject != null) ...<Widget>[
                        Row(
                          children: <Widget>[
                            SubjectIconBox(
                              iconKey: topSubject.iconKey,
                              size: 36,
                              iconSize: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Most Studied Subject',
                                    style: AppTypography.body16SemiBold,
                                  ),
                                  Text(
                                    topSubject.name,
                                    style: AppTypography.secondary14,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateTimeUtils.formatMinutes(topSubject.minutes),
                              style: AppTypography.body16SemiBold,
                            ),
                          ],
                        ),
                        const Divider(height: 22, color: AppColors.divider),
                      ],
                      _InsightRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Best Study Day',
                        value: controller.bestStudyDayLabel,
                      ),
                      const Divider(height: 22, color: AppColors.divider),
                      _InsightRow(
                        icon: Icons.access_time_rounded,
                        label: 'Average Session Duration',
                        value: DateTimeUtils.formatMinutes(
                          controller.averageSessionMinutes,
                        ),
                      ),
                      const Divider(height: 22, color: AppColors.divider),
                      const Text(
                        'Study Performance Summary',
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.performanceSummaryText,
                        style: AppTypography.secondary14,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              const Text('Explore', style: AppTypography.section18),
              const SizedBox(height: 12),
              PmWhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    PmListTileRow(
                      title: 'Goals & Streaks',
                      subtitle: '${controller.currentStreakDays}-day streak',
                      leading: const Icon(
                        Icons.local_fire_department_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.goals),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Achievements',
                      subtitle:
                          '${controller.unlockedAchievementsCount} of ${controller.totalAchievementsCount} unlocked',
                      leading: const Icon(
                        Icons.emoji_events_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.achievements),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Calendar',
                      subtitle: 'Study days and tasks',
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.calendar),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    PmListTileRow(
                      title: 'Session History',
                      subtitle:
                          '${controller.allSessions.length} sessions recorded',
                      leading: const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () => Get.toNamed<void>(AppRoutes.sessionHistory),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _OverviewStatCell extends StatelessWidget {
  const _OverviewStatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTypography.meta12),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.section18.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PeriodBarChartCard extends StatelessWidget {
  const _PeriodBarChartCard({required this.period, required this.buckets});

  final StatsPeriod period;
  final List<StatBarBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxMin = buckets.fold<int>(0, (m, b) => math.max(m, b.minutes));
    final stepY = maxMin <= 160
        ? 40.0
        : (maxMin <= 400 ? 100.0 : (maxMin <= 800 ? 200.0 : 400.0));
    final maxY = math.max((maxMin / stepY).ceil() * stepY, stepY * 4);

    return PmWhiteCard(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      child: SizedBox(
        height: 185,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            barTouchData: const BarTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: stepY,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: stepY,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${value.toInt()}m',
                        style: AppTypography.meta12.copyWith(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    if (period == StatsPeriod.year && idx.isEven) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(
                        buckets[idx].label,
                        style: AppTypography.meta12.copyWith(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List<BarChartGroupData>.generate(buckets.length, (i) {
              final bucket = buckets[i];
              return BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: bucket.minutes.toDouble(),
                    width: period == StatsPeriod.year ? 14 : 26,
                    color: bucket.isHighlighted
                        ? AppColors.primary
                        : AppColors.track,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SubjectDistributionCard extends StatelessWidget {
  const _SubjectDistributionCard({
    required this.totalLabel,
    required this.slices,
  });

  final String totalLabel;
  final List<SubjectSliceData> slices;

  @override
  Widget build(BuildContext context) {
    return PmWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                    sections: slices.map((slice) {
                      final color = AppColors.chartPalette[
                          slice.paletteIndex % AppColors.chartPalette.length];
                      return PieChartSectionData(
                        value: math.max(1, slice.minutes).toDouble(),
                        color: color,
                        radius: 24,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(totalLabel, style: AppTypography.section18),
                    const Text('total time', style: AppTypography.meta12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List<Widget>.generate(slices.length, (index) {
            final slice = slices[index];
            final color = AppColors.chartPalette[
                slice.paletteIndex % AppColors.chartPalette.length];
            return Padding(
              padding: EdgeInsets.only(bottom: index < slices.length - 1 ? 10 : 0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slice.name,
                      style: AppTypography.secondary14.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateTimeUtils.formatMinutes(slice.minutes),
                    style: AppTypography.secondary14,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${slice.percentage}%',
                      textAlign: TextAlign.right,
                      style: AppTypography.secondary14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DailyActivityLineCard extends StatelessWidget {
  const _DailyActivityLineCard({
    required this.points,
    required this.dailyGoalMinutes,
  });

  final List<DailyActivityPoint> points;
  final int dailyGoalMinutes;

  @override
  Widget build(BuildContext context) {
    final maxPoint = points.fold<int>(0, (m, p) => math.max(m, p.minutes));
    final maxY = math.max(
      math.max(maxPoint.toDouble(), dailyGoalMinutes.toDouble()),
      240.0,
    );
    final stepY = maxY <= 240 ? 60.0 : (maxY <= 480 ? 120.0 : 180.0);
    final labelStep = math.max(1, (points.length / 4).round());

    return PmWhiteCard(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      child: SizedBox(
        height: 185,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            lineTouchData: const LineTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: stepY,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              ),
            ),
            extraLinesData: dailyGoalMinutes > 0
                ? ExtraLinesData(
                    horizontalLines: <HorizontalLine>[
                      HorizontalLine(
                        y: dailyGoalMinutes.toDouble(),
                        color: AppColors.textMuted,
                        strokeWidth: 1.2,
                        dashArray: <int>[4, 4],
                      ),
                    ],
                  )
                : const ExtraLinesData(),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: stepY,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${value.toInt()}m',
                        style: AppTypography.meta12.copyWith(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final show = idx == 0 ||
                        idx == points.length - 1 ||
                        idx % labelStep == 0;
                    if (!show) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(
                        DateFormat('d MMM').format(points[idx].date),
                        style: AppTypography.meta12.copyWith(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: List<FlSpot>.generate(
                  points.length,
                  (i) => FlSpot(i.toDouble(), points[i].minutes.toDouble()),
                ),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.textPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTypography.body16Medium),
        ),
        const SizedBox(width: 8),
        Text(value, style: AppTypography.secondary14SemiBold),
      ],
    );
  }
}
