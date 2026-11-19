import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/enums/subject_visuals.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/main_shell_viewmodel.dart';

/// Home Dashboard matching 03 Home Dashboard.png and Home · No study activity.png.
class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<MainShellViewModel>();

    return SafeArea(
      child: Obx(() {
        final days = controller.weekDays;
        final tasks = controller.tasksForSelectedDate;
        final recent = controller.recentSessions;
        final selected = controller.selectedDate.value;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          controller.greeting,
                          style: AppTypography.title24,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ready to make today productive?',
                          style: AppTypography.secondary14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PmIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onPressed: () => Get.toNamed<void>(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                controller.selectedDateTitle,
                style: AppTypography.body16SemiBold,
              ),
              const SizedBox(height: 12),
              PmWeekDateStrip(
                days: days,
                selectedDate: selected,
                onSelectDate: controller.selectDate,
              ),
              const SizedBox(height: 18),
              _TodayProgressCard(controller: controller),
              const SizedBox(height: 12),
              _QuickStatsCard(controller: controller),
              const SizedBox(height: 18),
              PmPrimaryButton(
                label: 'Start Studying',
                icon: Icons.play_arrow_outlined,
                onPressed: () => Get.toNamed<void>(AppRoutes.sessionSetup),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PmSecondaryButton(
                      label: 'Add Subject',
                      icon: Icons.add_rounded,
                      onPressed: () => Get.toNamed<void>(AppRoutes.addSubject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PmSecondaryButton(
                      label: 'Plan Study',
                      icon: Icons.calendar_today_outlined,
                      onPressed: () => Get.toNamed<void>(AppRoutes.planner),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              PmSectionHeader(
                title: "Today's Schedule",
                actionLabel: 'See all',
                onActionTap: () => Get.toNamed<void>(AppRoutes.planner),
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                PmEmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Nothing planned',
                  subtitle: 'Plan a study task to see it here',
                  actionLabel: 'Plan Study',
                  actionIcon: Icons.add_rounded,
                  onAction: () => Get.toNamed<void>(AppRoutes.addTask),
                )
              else
                PmWhiteCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: List<Widget>.generate(tasks.length, (index) {
                      final task = tasks[index];
                      final subject = controller.subjectForId(task.subjectId);
                      final timeStr =
                          DateTimeUtils.formatTaskTimeLabel(task.scheduledTime);
                      final parts = <String>[
                        subject?.name ?? 'General Study',
                        if (timeStr.isNotEmpty) timeStr,
                      ];

                      return Column(
                        children: <Widget>[
                          PlannerTaskCard(
                            wrappedInCard: false,
                            title: task.title,
                            metaLabel: parts.join(' · '),
                            durationLabel:
                                DateTimeUtils.formatMinutes(task.targetMinutes),
                            subjectIdentifier: subject?.identifier,
                            isCompleted: task.isCompleted,
                            onToggleComplete: () => controller.toggleTask(task),
                            onTap: () => Get.toNamed<void>(
                              AppRoutes.editTask,
                              arguments: task.id,
                            ),
                          ),
                          if (index < tasks.length - 1)
                            const Divider(height: 1, color: AppColors.divider),
                        ],
                      );
                    }),
                  ),
                ),
              const SizedBox(height: AppSpacing.sectionGap),
              PmSectionHeader(
                title: 'Recent Activity',
                actionLabel: recent.isNotEmpty ? 'View stats' : null,
                onActionTap: () => shell.changeTab(3),
              ),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                const PmEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No sessions yet',
                  subtitle: 'Finished study sessions show up here',
                )
              else
                PmWhiteCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: List<Widget>.generate(recent.length, (index) {
                      final session = recent[index];
                      final subject = controller.subjectForId(session.subjectId);
                      final finishedAt = DateTime.fromMillisecondsSinceEpoch(
                        session.endedAtMs ?? session.startedAtMs,
                        isUtc: true,
                      );
                      final finishedLabel =
                          DateTimeUtils.formatClockTime(finishedAt);
                      return Column(
                        children: <Widget>[
                          StudySessionRow(
                            title: subject?.name ?? 'General Study',
                            subtitle:
                                '${session.sessionType.label} · Finished $finishedLabel',
                            durationLabel:
                                DateTimeUtils.formatSecondsAsMinutesLabel(
                              session.durationSeconds,
                            ),
                            icon: subject?.iconKey.iconData ??
                                session.sessionType.iconData,
                            onTap: () => Get.toNamed<void>(
                              AppRoutes.sessionHistory,
                            ),
                          ),
                          if (index < recent.length - 1)
                            const Divider(height: 1, color: AppColors.divider),
                        ],
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.controller});

  final HomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    return PmGreyCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Row(
        children: <Widget>[
          PmCircularProgress(
            size: 128,
            strokeWidth: 11,
            progress: controller.dailyProgressFraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${controller.dailyProgressPercent}%',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('of daily goal', style: AppTypography.meta12),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  controller.isSelectedToday
                      ? "Today's Progress"
                      : "Day's Progress",
                  style: AppTypography.secondary14SemiBold,
                ),
                const SizedBox(height: 6),
                Text(
                  controller.studiedDurationLabel,
                  style: AppTypography.display32,
                ),
                const SizedBox(height: 2),
                Text(
                  controller.targetDurationLabel,
                  style: AppTypography.secondary14,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.track),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: controller.remainingDurationLabel,
                        style: AppTypography.secondary14SemiBold,
                      ),
                      const TextSpan(
                        text: ' to go',
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
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.controller});

  final HomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    return PmWhiteCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _StatColumn(
                label: 'Study\nSessions',
                value: '${controller.sessionsCountForSelectedDate}',
                caption: controller.isSelectedToday ? 'today' : 'selected',
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            Expanded(
              child: _StatColumn(
                label: 'Focus Time',
                value: controller.focusTimeThisWeekLabel,
                caption: 'this week',
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            Expanded(
              child: _StatColumn(
                label: 'Current Streak',
                value: '${controller.currentStreakDays}',
                caption: 'days',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.meta12Medium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.section18.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(caption, style: AppTypography.meta12),
        ],
      ),
    );
  }
}
