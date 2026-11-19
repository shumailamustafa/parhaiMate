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
import '../viewmodels/calendar_viewmodel.dart';

/// Calendar screen matching 11 Calendar.png, April date, Month selector, and Empty state.
class CalendarView extends GetView<CalendarViewModel> {
  const CalendarView({super.key});

  static const List<String> _weekdayHeaders = <String>[
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
    return Obx(() {
      final month = controller.displayedMonth.value;
      final selectedDate = controller.selectedDate.value;
      final todayKey = controller.todayKey;
      final selectedKey = controller.selectedDateKey;
      final studiedKeys = controller.studiedDateKeys;
      final plannedKeys = controller.plannedDateKeys;
      final scheduled = controller.scheduledTasksForSelectedDate;
      final completed = controller.completedTasksForSelectedDate;
      final daySessions = controller.sessionsForSelectedDate;
      final studiedMinutes = controller.studiedMinutesForSelectedDate;

      final firstOfMonth = DateTime(month.year, month.month, 1);
      final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
      final leadingBlanks = firstOfMonth.weekday - 1;
      final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(
          title: 'Calendar',
          actions: <Widget>[
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
            ? const PmLoadingState(message: 'Loading calendar...')
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  8,
                  AppSpacing.screenPadding,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Previous month',
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: controller.previousMonth,
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: AppRadii.controlRadius,
                            onTap: () => _showMonthSelector(context, month),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                controller.monthTitle,
                                textAlign: TextAlign.center,
                                style: AppTypography.body16SemiBold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: controller.nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _weekdayHeaders
                          .map(
                            (label) => Expanded(
                              child: Center(
                                child: Text(label, style: AppTypography.meta12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    ...List<Widget>.generate(totalCells ~/ 7, (rowIdx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: List<Widget>.generate(7, (colIdx) {
                            final cellIndex = rowIdx * 7 + colIdx;
                            final dayNum = cellIndex - leadingBlanks + 1;
                            if (dayNum < 1 || dayNum > daysInMonth) {
                              return const Expanded(child: SizedBox(height: 46));
                            }
                            final cellDate =
                                DateTime(month.year, month.month, dayNum);
                            final key = DateTimeUtils.toDateKey(cellDate);
                            final isSelected = key == selectedKey;
                            final isToday = key == todayKey;
                            final hasStudied = studiedKeys.contains(key);
                            final hasPlanned = plannedKeys.contains(key);

                            return Expanded(
                              child: InkWell(
                                borderRadius: AppRadii.controlRadius,
                                onTap: () => controller.selectDate(cellDate),
                                child: SizedBox(
                                  height: 46,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: !isSelected && isToday
                                              ? Border.all(
                                                  color: AppColors.primary,
                                                  width: 1.5,
                                                )
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$dayNum',
                                          style: AppTypography.secondary14
                                              .copyWith(
                                            color: isSelected
                                                ? AppColors.onPrimary
                                                : AppColors.textPrimary,
                                            fontWeight: (isSelected || isToday)
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      _DayDotIndicator(
                                        hasStudied: hasStudied,
                                        hasPlanned: hasPlanned,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _LegendDot(filled: true, label: 'Studied'),
                        SizedBox(width: 20),
                        _LegendDot(filled: false, label: 'Planned'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Text(
                      controller.selectedDateTitle,
                      style: AppTypography.body16SemiBold,
                    ),
                    const SizedBox(height: 12),
                    PmGreyCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Study time',
                                    style: AppTypography.meta12,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateTimeUtils.formatMinutes(studiedMinutes),
                                    style: AppTypography.section18,
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(
                              width: 24,
                              thickness: 1,
                              color: AppColors.track,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Sessions',
                                    style: AppTypography.meta12,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${daySessions.length}',
                                    style: AppTypography.section18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (scheduled.isEmpty &&
                        completed.isEmpty &&
                        daySessions.isEmpty)
                      PmEmptyState(
                        icon: Icons.event_busy_outlined,
                        title:
                            'No study activity on ${DateTimeUtils.formatShortDate(selectedDate)}',
                        subtitle: 'Plan a task for this day or pick another date',
                        actionLabel: 'Add Task',
                        actionIcon: Icons.add_rounded,
                        onAction: () => Get.toNamed<void>(
                          AppRoutes.addTask,
                          arguments: <String, dynamic>{'date': selectedDate},
                        ),
                      )
                    else ...<Widget>[
                      const Text(
                        'Scheduled tasks',
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 10),
                      if (scheduled.isEmpty)
                        const Text(
                          'No scheduled tasks',
                          style: AppTypography.secondary14,
                        )
                      else
                        ...List<Widget>.generate(scheduled.length, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < scheduled.length - 1 ? 10 : 0,
                            ),
                            child: _buildTaskRow(scheduled[index]),
                          );
                        }),
                      const SizedBox(height: 20),
                      const Text(
                        'Completed tasks',
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 10),
                      if (completed.isEmpty)
                        const Text(
                          'No completed tasks',
                          style: AppTypography.secondary14,
                        )
                      else
                        ...List<Widget>.generate(completed.length, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < completed.length - 1 ? 10 : 0,
                            ),
                            child: _buildTaskRow(completed[index]),
                          );
                        }),
                      const SizedBox(height: 20),
                      const Text(
                        'Sessions',
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 10),
                      if (daySessions.isEmpty)
                        const Text(
                          'No sessions recorded',
                          style: AppTypography.secondary14,
                        )
                      else
                        PmWhiteCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: List<Widget>.generate(
                              daySessions.length,
                              (index) {
                                final session = daySessions[index];
                                final subject = controller.subjectForId(
                                  session.subjectId,
                                );
                                final finishedAt =
                                    DateTime.fromMillisecondsSinceEpoch(
                                  session.endedAtMs ?? session.startedAtMs,
                                  isUtc: true,
                                );
                                return Column(
                                  children: <Widget>[
                                    StudySessionRow(
                                      title: subject?.name ?? 'General Study',
                                      subtitle:
                                          '${session.sessionType.label} · Finished ${DateTimeUtils.formatClockTime(finishedAt)}',
                                      durationLabel: DateTimeUtils
                                          .formatSecondsAsMinutesLabel(
                                        session.durationSeconds,
                                      ),
                                      icon: subject?.iconKey.iconData ??
                                          session.sessionType.iconData,
                                    ),
                                    if (index < daySessions.length - 1)
                                      const Divider(
                                        height: 1,
                                        color: AppColors.divider,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildTaskRow(PlannerTaskEntity task) {
    final subject = controller.subjectForId(task.subjectId);
    final timeStr = DateTimeUtils.formatTaskTimeLabel(task.scheduledTime);
    final parts = <String>[
      subject?.name ?? 'General Study',
      if (timeStr.isNotEmpty) timeStr,
    ];

    return PlannerTaskCard(
      title: task.title,
      metaLabel: parts.join(' · '),
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

  Future<void> _showMonthSelector(
    BuildContext context,
    DateTime currentMonth,
  ) {
    return PmBottomSheet.show<void>(
      context: context,
      title: 'Select month',
      child: _MonthYearSelectorSheet(
        initialMonth: currentMonth,
        onSelected: (year, month) {
          controller.selectMonthYear(year, month);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _DayDotIndicator extends StatelessWidget {
  const _DayDotIndicator({
    required this.hasStudied,
    required this.hasPlanned,
  });

  final bool hasStudied;
  final bool hasPlanned;

  @override
  Widget build(BuildContext context) {
    if (!hasStudied && !hasPlanned) {
      return const SizedBox(height: 5);
    }
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasStudied ? AppColors.primary : Colors.transparent,
        border: hasStudied
            ? null
            : Border.all(color: AppColors.primary, width: 1.2),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.filled, required this.label});

  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : Colors.transparent,
            border: filled
                ? null
                : Border.all(color: AppColors.primary, width: 1.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.meta12),
      ],
    );
  }
}

class _MonthYearSelectorSheet extends StatefulWidget {
  const _MonthYearSelectorSheet({
    required this.initialMonth,
    required this.onSelected,
  });

  final DateTime initialMonth;
  final void Function(int year, int month) onSelected;

  @override
  State<_MonthYearSelectorSheet> createState() =>
      _MonthYearSelectorSheetState();
}

class _MonthYearSelectorSheetState extends State<_MonthYearSelectorSheet> {
  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final baseYear = widget.initialMonth.year;
    final years = <int>[baseYear - 1, baseYear];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PmSegmentedControl<int>(
          selectedValue: _selectedYear,
          onChanged: (year) => setState(() => _selectedYear = year),
          options: years
              .map(
                (y) => PmSegmentOption<int>(value: y, label: '$y'),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.35,
          children: List<Widget>.generate(12, (index) {
            final monthNumber = index + 1;
            final isSelected = _selectedYear == widget.initialMonth.year &&
                monthNumber == widget.initialMonth.month;
            return Material(
              color: isSelected ? AppColors.primary : AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.pillRadius,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: InkWell(
                borderRadius: AppRadii.pillRadius,
                onTap: () => widget.onSelected(_selectedYear, monthNumber),
                child: Center(
                  child: Text(
                    _monthNames[index],
                    style: AppTypography.secondary14SemiBold.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
