import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../shared/enums/subject_visuals.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/subject_details_viewmodel.dart';

/// Subject Details screen matching 09 Subject Details.png & variants.
class SubjectDetailsView extends GetView<SubjectDetailsViewModel> {
  const SubjectDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.subject.value;

      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          appBar: PmAppBar(title: 'Subject Details'),
          body: PmLoadingState(message: 'Loading subject details...'),
        );
      }

      if (s == null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const PmAppBar(title: 'Subject Details'),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: PmEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Subject not found',
              subtitle: 'This subject may have been deleted.',
              actionLabel: 'Go Back',
              onAction: () => Navigator.of(context).maybePop(),
            ),
          ),
        );
      }

      final sessions = controller.sessions;
      final preview = controller.previewSessions;
      final dayMinutes = controller.weeklyDayMinutes;
      final dailyTarget = controller.dailyTargetMinutes;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(
          title: s.name,
          actions: <Widget>[
            IconButton(
              tooltip: 'Edit Subject',
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Get.toNamed<void>(
                AppRoutes.editSubject,
                arguments: s.id,
              ),
            ),
            IconButton(
              tooltip: 'Subject actions',
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => _showMoreOptionsSheet(context, s),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            12,
            AppSpacing.screenPadding,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _OverviewCard(
                subject: s,
                totalMinutes: controller.totalMinutes,
                sessionsCount: sessions.length,
                weekMinutes: controller.weekMinutes,
                weekProgress: controller.weekProgress,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const Text('Study Statistics', style: AppTypography.section18),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatisticsMetricCard(
                      label: 'Today',
                      value:
                          DateTimeUtils.formatMinutes(controller.todayMinutes),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatisticsMetricCard(
                      label: 'This week',
                      value:
                          DateTimeUtils.formatMinutes(controller.weekMinutes),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatisticsMetricCard(
                      label: 'This month',
                      value:
                          DateTimeUtils.formatMinutes(controller.monthMinutes),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatisticsMetricCard(
                      label: 'Average session',
                      value: DateTimeUtils.formatMinutes(
                        controller.averageSessionMinutes,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const Text('This week', style: AppTypography.section18),
              const SizedBox(height: 12),
              _WeeklySubjectBarCard(
                dayMinutes: dayMinutes,
                dailyTargetMinutes: dailyTarget,
                weekTotalMinutes: controller.weekMinutes,
                todayWeekdayIndex: controller.currentTodayWeekdayIndex,
              ),
              const SizedBox(height: 16),
              PmPrimaryButton(
                label: 'Start Studying This Subject',
                icon: Icons.play_arrow_outlined,
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.sessionSetup,
                  arguments: <String, dynamic>{'subjectId': s.id},
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              PmSectionHeader(
                title: 'Session History',
                actionLabel: sessions.isNotEmpty
                    ? 'Show all ${sessions.length} ${sessions.length == 1 ? 'session' : 'sessions'}'
                    : null,
                onActionTap: () => Get.toNamed<void>(
                  AppRoutes.sessionHistory,
                  arguments: s.id,
                ),
              ),
              const SizedBox(height: 12),
              if (preview.isEmpty)
                const PmEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No sessions yet',
                  subtitle: 'Start a session for this subject to see it here',
                )
              else
                PmWhiteCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: List<Widget>.generate(preview.length, (index) {
                      final session = preview[index];
                      final timeStr = DateTimeUtils.formatClockTime(
                        DateTime.fromMillisecondsSinceEpoch(
                          session.startedAtMs,
                          isUtc: true,
                        ),
                      );
                      return Column(
                        children: <Widget>[
                          StudySessionRow(
                            title: controller.formatSessionDateHeading(
                              session.startedAtMs,
                            ),
                            subtitle: '${session.sessionType.label} · $timeStr',
                            durationLabel:
                                DateTimeUtils.formatSecondsAsMinutesLabel(
                              session.durationSeconds,
                            ),
                            icon: session.sessionType.iconData,
                          ),
                          if (index < preview.length - 1)
                            const Divider(height: 1, color: AppColors.divider),
                        ],
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PmSecondaryButton(
                      label: 'Edit Subject',
                      icon: Icons.edit_outlined,
                      size: PmButtonSize.medium,
                      onPressed: () => Get.toNamed<void>(
                        AppRoutes.editSubject,
                        arguments: s.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PmSecondaryButton(
                      label: s.isArchived ? 'Restore Subject' : 'Archive Subject',
                      icon: s.isArchived
                          ? Icons.refresh_rounded
                          : Icons.archive_outlined,
                      size: PmButtonSize.medium,
                      onPressed: controller.toggleArchive,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _showMoreOptionsSheet(
    BuildContext context,
    SubjectEntity subject,
  ) {
    return PmBottomSheet.show<void>(
      context: context,
      title: 'Subject actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PmListTileRow(
            title: 'Edit Subject',
            leading: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onTap: () {
              Navigator.of(context).pop();
              Get.toNamed<void>(AppRoutes.editSubject, arguments: subject.id);
            },
          ),
          const Divider(height: 1, color: AppColors.divider),
          PmListTileRow(
            title: subject.isArchived ? 'Restore Subject' : 'Archive Subject',
            leading: Icon(
              subject.isArchived
                  ? Icons.refresh_rounded
                  : Icons.archive_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              await controller.toggleArchive();
              if (context.mounted) {
                navigator.pop();
              }
            },
          ),
          const Divider(height: 1, color: AppColors.divider),
          PmListTileRow(
            title: 'Delete Subject',
            leading: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteDialog(context, subject);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    SubjectEntity subject,
  ) async {
    final sCount = controller.sessions.length;
    final tCount = controller.linkedTasksCount.value;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete ${subject.name}?',
        message:
            "Its $sCount sessions and $tCount planned tasks will be deleted too. You can't undo this.",
        confirmLabel: 'Delete Subject',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed ?? false) {
      await controller.deleteSubjectAndExit();
    }
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.subject,
    required this.totalMinutes,
    required this.sessionsCount,
    required this.weekMinutes,
    required this.weekProgress,
  });

  final SubjectEntity subject;
  final int totalMinutes;
  final int sessionsCount;
  final int weekMinutes;
  final double weekProgress;

  @override
  Widget build(BuildContext context) {
    return PmGreyCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadii.controlRadius,
                ),
                alignment: Alignment.center,
                child: Icon(
                  subject.iconKey.iconData,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SubjectIdentifierBadge(identifier: subject.identifier),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subject.name,
                            style: AppTypography.section18,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (subject.isArchived) ...<Widget>[
                      const SizedBox(height: 2),
                      const Text('Archived', style: AppTypography.secondary14),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.track),
          const Text('Total study time', style: AppTypography.secondary14),
          const SizedBox(height: 4),
          Text(
            DateTimeUtils.formatMinutes(totalMinutes),
            style: AppTypography.display32,
          ),
          const SizedBox(height: 2),
          Text(
            '$sessionsCount ${sessionsCount == 1 ? 'session' : 'sessions'}',
            style: AppTypography.secondary14,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('This week', style: AppTypography.secondary14),
              ),
              Text(
                '${DateTimeUtils.formatMinutes(weekMinutes)} of ${DateTimeUtils.formatMinutes(subject.targetMinutes)}',
                style: AppTypography.secondary14SemiBold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          PmProgressBar(progress: weekProgress, height: 7),
        ],
      ),
    );
  }
}

class _WeeklySubjectBarCard extends StatelessWidget {
  const _WeeklySubjectBarCard({
    required this.dayMinutes,
    required this.dailyTargetMinutes,
    required this.weekTotalMinutes,
    required this.todayWeekdayIndex,
  });

  final List<int> dayMinutes;
  final int dailyTargetMinutes;
  final int weekTotalMinutes;
  final int todayWeekdayIndex;

  static const List<String> _dayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final maxStudied = dayMinutes.fold<int>(0, math.max);
    final maxY = math.max(
      math.max(maxStudied.toDouble(), dailyTargetMinutes.toDouble()) * 1.25,
      60.0,
    );

    return PmWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Daily target · ${DateTimeUtils.formatMinutes(dailyTargetMinutes)}',
                  style: AppTypography.meta12,
                ),
              ),
              Text(
                '${DateTimeUtils.formatMinutes(weekTotalMinutes)} total',
                style: AppTypography.meta12,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: const BarTouchData(enabled: false),
                extraLinesData: dailyTargetMinutes > 0
                    ? ExtraLinesData(
                        horizontalLines: <HorizontalLine>[
                          HorizontalLine(
                            y: dailyTargetMinutes.toDouble(),
                            color: AppColors.track,
                            strokeWidth: 1,
                            dashArray: <int>[4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: AppTypography.meta12.copyWith(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                              labelResolver: (_) => 'Daily target',
                            ),
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        final isToday = idx == todayWeekdayIndex;
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            _dayLabels[idx],
                            style: AppTypography.meta12.copyWith(
                              color: isToday
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight:
                                  isToday ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(7, (index) {
                  final minutes = dayMinutes[index].toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: minutes > 0 ? minutes : 1.5,
                        width: 24,
                        color: minutes > 0
                            ? AppColors.primary
                            : (index == todayWeekdayIndex
                                ? AppColors.primary
                                : AppColors.track),
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
        ],
      ),
    );
  }
}
