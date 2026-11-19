import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/planner_viewmodel.dart';

/// Study Planner screen matching 10 Study Planner.png and all empty/tab states.
class StudyPlannerView extends GetView<PlannerViewModel> {
  const StudyPlannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasAnyTasks = controller.allTasks.isNotEmpty;
      final weekDays = controller.weekDays;
      final selectedDate = controller.selectedDate.value;
      final tab = controller.activeTab.value;
      final dayTabLabel = controller.dayTabLabel;
      final pending = controller.pendingForSelectedDate;
      final done = controller.completedForSelectedDate;
      final upcoming = controller.upcomingGroups;
      final completed = controller.completedGroups;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(
          title: 'Study Planner',
          actions: <Widget>[
            PmIconButton(
              icon: Icons.calendar_today_outlined,
              variant: PmIconButtonVariant.plain,
              tooltip: 'Calendar',
              onPressed: () => Get.toNamed<void>(AppRoutes.calendar),
            ),
            const SizedBox(width: 4),
            PmIconButton(
              icon: Icons.add_rounded,
              variant: PmIconButtonVariant.navy,
              tooltip: 'Add Task',
              onPressed: () => Get.toNamed<void>(
                AppRoutes.addTask,
                arguments: <String, dynamic>{'date': selectedDate},
              ),
            ),
          ],
        ),
        body: controller.isLoading.value
            ? const PmLoadingState(message: 'Loading study planner...')
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  12,
                  AppSpacing.screenPadding,
                  28,
                ),
                child: !hasAnyTasks
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: PmEmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'No study tasks yet',
                          subtitle:
                              'Plan what to study and when, then tick tasks off as you go',
                          actionLabel: 'Add Task',
                          actionIcon: Icons.add_rounded,
                          onAction: () => Get.toNamed<void>(
                            AppRoutes.addTask,
                            arguments: <String, dynamic>{'date': selectedDate},
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Previous week',
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: controller.previousWeek,
                              ),
                              Expanded(
                                child: Text(
                                  controller.weekRangeLabel,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body16SemiBold,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Next week',
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: controller.nextWeek,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PmWeekDateStrip(
                            days: weekDays,
                            selectedDate: selectedDate,
                            onSelectDate: controller.selectDate,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            controller.daySummaryLabel,
                            style: AppTypography.secondary14,
                          ),
                          const SizedBox(height: 14),
                          PmSegmentedControl<PlannerTab>(
                            selectedValue: tab,
                            onChanged: controller.setTab,
                            options: <PmSegmentOption<PlannerTab>>[
                              PmSegmentOption<PlannerTab>(
                                value: PlannerTab.day,
                                label: dayTabLabel,
                              ),
                              const PmSegmentOption<PlannerTab>(
                                value: PlannerTab.upcoming,
                                label: 'Upcoming',
                              ),
                              const PmSegmentOption<PlannerTab>(
                                value: PlannerTab.completed,
                                label: 'Completed',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (tab == PlannerTab.day)
                            _buildDayContent(
                              context,
                              selectedDate: selectedDate,
                              pending: pending,
                              done: done,
                            )
                          else if (tab == PlannerTab.upcoming)
                            _buildGroupList(
                              groups: upcoming,
                              emptyTitle: 'No upcoming tasks',
                              emptySubtitle:
                                  'Scheduled tasks for future days will show up here',
                              selectedDate: selectedDate,
                            )
                          else
                            _buildGroupList(
                              groups: completed,
                              emptyTitle: 'No completed tasks yet',
                              emptySubtitle:
                                  'Tasks you mark as done will show up here',
                              selectedDate: selectedDate,
                            ),
                        ],
                      ),
              ),
      );
    });
  }

  Widget _buildDayContent(
    BuildContext context, {
    required DateTime selectedDate,
    required List<PlannerTaskEntity> pending,
    required List<PlannerTaskEntity> done,
  }) {
    if (pending.isEmpty && done.isEmpty) {
      return PmEmptyState(
        icon: Icons.event_available_outlined,
        title:
            'Nothing planned for ${DateTimeUtils.formatShortDate(selectedDate)}',
        subtitle: 'Add a task for this day',
        actionLabel: 'Add Task',
        actionIcon: Icons.add_rounded,
        onAction: () => Get.toNamed<void>(
          AppRoutes.addTask,
          arguments: <String, dynamic>{'date': selectedDate},
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ...List<Widget>.generate(pending.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < pending.length - 1 ? 10 : 0),
            child: _buildTaskItem(pending[index], includeDateInMeta: false),
          );
        }),
        if (done.isNotEmpty) ...<Widget>[
          SizedBox(height: pending.isEmpty ? 0 : 20),
          const Text(
            'DONE',
            style: AppTypography.meta12SemiBold,
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(done.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < done.length - 1 ? 10 : 0),
              child: _buildTaskItem(done[index], includeDateInMeta: false),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildGroupList({
    required List<PlannerTaskGroup> groups,
    required String emptyTitle,
    required String emptySubtitle,
    required DateTime selectedDate,
  }) {
    if (groups.isEmpty) {
      return PmEmptyState(
        icon: Icons.event_available_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: 'Add Task',
        actionIcon: Icons.add_rounded,
        onAction: () => Get.toNamed<void>(
          AppRoutes.addTask,
          arguments: <String, dynamic>{'date': selectedDate},
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(groups.length, (gIndex) {
        final group = groups[gIndex];
        return Padding(
          padding: EdgeInsets.only(
            bottom: gIndex < groups.length - 1 ? 20 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(group.heading, style: AppTypography.body16SemiBold),
              const SizedBox(height: 10),
              ...List<Widget>.generate(group.tasks.length, (tIndex) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: tIndex < group.tasks.length - 1 ? 10 : 0,
                  ),
                  child: _buildTaskItem(
                    group.tasks[tIndex],
                    includeDateInMeta: true,
                    datePrefix: group.heading,
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTaskItem(
    PlannerTaskEntity task, {
    required bool includeDateInMeta,
    String? datePrefix,
  }) {
    final subject = controller.subjectForId(task.subjectId);
    final timeLabel = DateTimeUtils.formatTaskTimeLabel(task.scheduledTime);
    final whenParts = <String>[
      if (includeDateInMeta && datePrefix != null) datePrefix,
      if (timeLabel.isNotEmpty) timeLabel,
    ];
    final metaParts = <String>[
      subject?.name ?? 'General Study',
      if (whenParts.isNotEmpty) whenParts.join(', '),
    ];

    return PlannerTaskCard(
      title: task.title,
      metaLabel: metaParts.join(' · '),
      durationLabel: DateTimeUtils.formatMinutes(task.targetMinutes),
      subjectIdentifier: subject?.identifier,
      isCompleted: task.isCompleted,
      onToggleComplete: () => controller.toggleTask(task),
      onTap: () => Get.toNamed<void>(
        AppRoutes.editTask,
        arguments: task.id,
      ),
    );
  }
}
