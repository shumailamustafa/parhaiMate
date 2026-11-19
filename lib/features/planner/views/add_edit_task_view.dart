import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/widgets.dart';
import '../../timer/widgets/timer_pickers.dart';
import '../viewmodels/task_form_viewmodel.dart';

/// Add / Edit Study Task screen matching Add Study Task.png & Edit Study Task.png.
class AddEditTaskView extends GetView<TaskFormViewModel> {
  const AddEditTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing;
      final current = controller.editingTask.value;
      final subject = controller.selectedSubject;
      final duration = controller.targetMinutes.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(
          title: isEditing ? 'Edit Study Task' : 'Add Study Task',
          actions: isEditing && current != null
              ? <Widget>[
                  IconButton(
                    tooltip: 'Delete task',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _showDeleteConfirmation(context, current.title),
                  ),
                ]
              : null,
        ),
        body: controller.isLoading.value
            ? const PmLoadingState(message: 'Loading study task...')
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
                            label: 'Task title',
                            hintText: 'e.g. Review chapter 4',
                            controller: controller.titleController,
                            errorText: controller.titleError.value,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),
                          PmDropdownField(
                            label: 'Subject (optional)',
                            placeholder: 'General Study',
                            valueText: subject?.name ?? 'General Study',
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
                              selectedSubjectId:
                                  controller.selectedSubjectId.value,
                              onSelected: controller.selectSubject,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PmDropdownField(
                            label: 'Date',
                            valueText: controller.formattedDateLabel,
                            leading: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            trailingIcon: Icons.chevron_right_rounded,
                            onTap: () => _showChooseDateSheet(context),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: PmDropdownField(
                                  label: 'Time',
                                  valueText: controller.formattedTimeLabel,
                                  onTap: () => _showTimePickerSheet(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PmDropdownField(
                                  label: 'Target duration',
                                  valueText: controller.formattedDurationSummary,
                                  onTap: () => _showDurationPickerSheet(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: TaskFormViewModel.durationChoices.map(
                              (minutes) {
                                return PmChip(
                                  label: '$minutes min',
                                  selected: duration == minutes,
                                  onTap: () => controller.selectDuration(minutes),
                                );
                              },
                            ).toList(),
                          ),
                          const SizedBox(height: 14),
                          PmStepperField(
                            valueLabel: '$duration min',
                            canDecrement:
                                duration > TaskFormViewModel.minDurationMinutes,
                            canIncrement:
                                duration < TaskFormViewModel.maxDurationMinutes,
                            onDecrement: () => controller.adjustDuration(
                              -TaskFormViewModel.durationStepMinutes,
                            ),
                            onIncrement: () => controller.adjustDuration(
                              TaskFormViewModel.durationStepMinutes,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PmTextArea(
                            label: 'Notes (optional)',
                            hintText: 'Add a note for this task',
                            controller: controller.notesController,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          PmPrimaryButton(
                            label: 'Save Task',
                            isLoading: controller.isSaving.value,
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final saved = await controller.saveTask();
                              if (saved && context.mounted) {
                                navigator.pop(true);
                              }
                            },
                          ),
                          if (isEditing && current != null) ...<Widget>[
                            const SizedBox(height: 10),
                            PmSecondaryButton(
                              label: current.isCompleted
                                  ? 'Mark as incomplete'
                                  : 'Mark as done',
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await controller.toggleDoneAndExit();
                                if (context.mounted) {
                                  navigator.pop(true);
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: PmGhostButton(
                                label: 'Start studying now',
                                onPressed: controller.startStudyingNow,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Future<void> _showChooseDateSheet(BuildContext context) {
    return PmBottomSheet.show<void>(
      context: context,
      title: 'Choose date',
      child: _TaskDatePickerSheet(
        initialDate: controller.selectedDate.value,
        today: controller.today,
        onSelected: controller.selectDate,
      ),
    );
  }

  Future<void> _showTimePickerSheet(BuildContext context) {
    const quickTimes = <MapEntry<String, String>>[
      MapEntry<String, String>('09:00', '9:00 AM'),
      MapEntry<String, String>('12:00', '12:00 PM'),
      MapEntry<String, String>('14:00', '2:00 PM'),
      MapEntry<String, String>('16:00', '4:00 PM'),
      MapEntry<String, String>('18:00', '6:00 PM'),
      MapEntry<String, String>('20:00', '8:00 PM'),
      MapEntry<String, String>('21:00', '9:00 PM'),
    ];

    return PmBottomSheet.show<void>(
      context: context,
      title: 'Choose time',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickTimes.map((entry) {
              return PmChip(
                label: entry.value,
                selected: controller.scheduledTime.value == entry.key,
                onTap: () {
                  controller.selectTimeKey(entry.key);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          PmSecondaryButton(
            label: 'Pick custom time',
            icon: Icons.access_time_rounded,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final picked = await showTimePicker(
                context: context,
                initialTime: controller.currentTimeOfDay,
                builder: (pickerContext, child) {
                  return Theme(
                    data: Theme.of(pickerContext).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: AppColors.onPrimary,
                        surface: AppColors.card,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && context.mounted) {
                controller.selectTime(picked);
                navigator.pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDurationPickerSheet(BuildContext context) {
    return PmBottomSheet.show<void>(
      context: context,
      title: 'Target duration',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TaskFormViewModel.durationChoices.map((minutes) {
              return PmChip(
                label: '$minutes min',
                selected: controller.targetMinutes.value == minutes,
                onTap: () {
                  controller.selectDuration(minutes);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete this task?',
        message:
            '“$title” will be removed from your planner. You can\'t undo this.',
        confirmLabel: 'Delete Task',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      final navigator = Navigator.of(context);
      await controller.deleteTask();
      if (context.mounted) {
        navigator.pop(true);
      }
    }
  }
}

class _TaskDatePickerSheet extends StatefulWidget {
  const _TaskDatePickerSheet({
    required this.initialDate,
    required this.today,
    required this.onSelected,
  });

  final DateTime initialDate;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_TaskDatePickerSheet> createState() => _TaskDatePickerSheetState();
}

class _TaskDatePickerSheetState extends State<_TaskDatePickerSheet> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

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
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = widget.today.add(const Duration(days: 1));
    final isToday = DateTimeUtils.toDateKey(_selectedDate) ==
        DateTimeUtils.toDateKey(widget.today);
    final isTomorrow = DateTimeUtils.toDateKey(_selectedDate) ==
        DateTimeUtils.toDateKey(tomorrow);

    final firstOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final leadingOffset = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingOffset));
    final totalCells = ((leadingOffset + daysInMonth) / 7).ceil() * 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            PmChip(
              label: 'Today',
              selected: isToday,
              onTap: () {
                widget.onSelected(widget.today);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 10),
            PmChip(
              label: 'Tomorrow',
              selected: isTomorrow,
              onTap: () {
                widget.onSelected(tomorrow);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                setState(() {
                  _displayedMonth = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month - 1,
                  );
                });
              },
            ),
            Expanded(
              child: Text(
                DateTimeUtils.formatMonthYear(_displayedMonth),
                textAlign: TextAlign.center,
                style: AppTypography.body16SemiBold,
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                setState(() {
                  _displayedMonth = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        ...List<Widget>.generate(totalCells ~/ 7, (rowIdx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List<Widget>.generate(7, (colIdx) {
                final cellDate =
                    gridStart.add(Duration(days: rowIdx * 7 + colIdx));
                final inMonth = cellDate.month == _displayedMonth.month;
                final isSelected = DateTimeUtils.toDateKey(cellDate) ==
                    DateTimeUtils.toDateKey(_selectedDate);

                return Expanded(
                  child: InkWell(
                    borderRadius: AppRadii.pillRadius,
                    onTap: () {
                      setState(() => _selectedDate = cellDate);
                      widget.onSelected(cellDate);
                      Navigator.of(context).pop();
                    },
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${cellDate.day}',
                            style: AppTypography.secondary14.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : (inMonth
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
