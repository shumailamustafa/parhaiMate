import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/enums/subject_visuals.dart';
import '../../../shared/widgets/widgets.dart';

/// Interactive design-system showcase matching Component Library.png.
class ComponentLibraryView extends StatefulWidget {
  const ComponentLibraryView({super.key});

  @override
  State<ComponentLibraryView> createState() => _ComponentLibraryViewState();
}

class _ComponentLibraryViewState extends State<ComponentLibraryView> {
  int _navIndex = 0;
  String _segment = 'Week';
  int _stepperMin = 25;
  bool _checked = true;
  bool _toggle = true;
  TimerMode _selectedMode = TimerMode.focus;
  DateTime _selectedDate = DateTime(2026, 5, 12);

  @override
  Widget build(BuildContext context) {
    final weekDays = List<PmWeekDayItem>.generate(7, (i) {
      const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final day = 11 + i;
      return PmWeekDayItem(
        date: DateTime(2026, 5, day),
        dayShort: names[i],
        dayNumber: '$day',
        hasActivity: i <= 1,
        isToday: day == 12,
      );
    });

    return Scaffold(
      appBar: const PmAppBar(title: 'Component Library'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Shared building blocks, shown with live app data and interactive states.',
              style: AppTypography.secondary14,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const PmSectionHeader(title: 'Foundations'),
            const SizedBox(height: 12),
            PmWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Display 32 semibold', style: AppTypography.display32),
                  const SizedBox(height: 6),
                  const Text('Title 24', style: AppTypography.title24),
                  const SizedBox(height: 6),
                  const Text('Section 18 semibold', style: AppTypography.section18),
                  const SizedBox(height: 6),
                  const Text('Body 16', style: AppTypography.body16),
                  const SizedBox(height: 4),
                  const Text('Secondary 14 muted', style: AppTypography.secondary14),
                  const SizedBox(height: 4),
                  const Text('Meta 12 muted', style: AppTypography.meta12),
                  const SizedBox(height: 8),
                  Text('Timer 68', style: AppTypography.timer68.copyWith(fontSize: 48)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const PmSectionHeader(title: 'Buttons'),
            const SizedBox(height: 12),
            PmPrimaryButton(label: 'Default action', onPressed: () {}),
            const SizedBox(height: 10),
            PmPrimaryButton(
              label: 'With icon',
              icon: Icons.add_rounded,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            PmPrimaryButton(
              label: 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            const PmPrimaryButton(label: 'Disabled', onPressed: null),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                PmSecondaryButton(
                  label: 'Secondary',
                  fullWidth: false,
                  size: PmButtonSize.medium,
                  onPressed: () {},
                ),
                PmGhostButton(
                  label: 'View details',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {},
                ),
                PmDestructiveButton(
                  label: 'Delete history',
                  icon: Icons.delete_outline_rounded,
                  fullWidth: false,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                PmIconButton(
                  icon: Icons.search_rounded,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                PmIconButton(
                  icon: Icons.calendar_today_outlined,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                PmIconButton(
                  icon: Icons.tune_rounded,
                  variant: PmIconButtonVariant.grey,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                PmIconButton(
                  icon: Icons.add_rounded,
                  variant: PmIconButtonVariant.navy,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const PmSectionHeader(title: 'Cards'),
            const SizedBox(height: 12),
            const Row(
              children: <Widget>[
                Expanded(
                  child: StatisticsMetricCard(
                    label: 'Focus time',
                    value: '2h 30m',
                    isPrimarySurface: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatisticsMetricCard(
                    label: 'Daily goal',
                    value: '4h',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SubjectCard(
              name: 'Mathematics',
              iconKey: SubjectIconKey.sigma,
              identifier: SubjectIdentifier.circle,
              totalLabel: '14h 20m total',
              weekStudiedLabel: '1h 52m',
              weekTargetLabel: '5h',
              weekProgress: 0.37,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            const StudySessionCard(
              title: 'Database Systems',
              subtitle: 'Today · Stopwatch · 1:10 PM',
              durationLabel: '55m',
              icon: Icons.storage_rounded,
            ),
            const SizedBox(height: 12),
            PlannerTaskCard(
              title: 'Revise integration by parts',
              metaLabel: 'Mathematics · Today, 4:00 PM',
              durationLabel: '45m',
              subjectIdentifier: SubjectIdentifier.circle,
              isCompleted: _checked,
              onToggleComplete: () => setState(() => _checked = !_checked),
            ),
            const SizedBox(height: 12),
            TimerModeCard(
              mode: TimerMode.focus,
              metaText: '25 min',
              description: 'Stay focused for a set amount of time.',
              selected: _selectedMode == TimerMode.focus,
              onTap: () => setState(() => _selectedMode = TimerMode.focus),
            ),
            const SizedBox(height: 12),
            const Row(
              children: <Widget>[
                Expanded(
                  child: AchievementCard(
                    icon: Icons.play_arrow_outlined,
                    title: 'First Session',
                    description: 'Complete your first study session.',
                    unlocked: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AchievementCard(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Time Master',
                    description: 'Complete 50 hours of study.',
                    unlocked: false,
                    progress: 0.9,
                    progressLabel: '45 of 50 hours',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const PmSectionHeader(title: 'Progress'),
            const SizedBox(height: 12),
            const PmProgressBar(progress: 0.63),
            const SizedBox(height: 14),
            const Center(
              child: PmCircularProgress(
                progress: 0.63,
                child: Text('63%', style: AppTypography.section18),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const PmSectionHeader(title: 'Inputs'),
            const SizedBox(height: 12),
            const PmTextField(
              label: 'Subject name',
              hintText: 'Add a subject',
            ),
            const SizedBox(height: 12),
            const PmTextField(
              label: 'Subject name',
              hintText: 'Add a subject',
              errorText: 'Enter a subject name',
            ),
            const SizedBox(height: 12),
            PmWeekDateStrip(
              days: weekDays,
              selectedDate: _selectedDate,
              onSelectDate: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 12),
            PmSegmentedControl<String>(
              selectedValue: _segment,
              options: const <PmSegmentOption<String>>[
                PmSegmentOption(value: 'Week', label: 'Week'),
                PmSegmentOption(value: 'Month', label: 'Month'),
                PmSegmentOption(value: 'Year', label: 'Year'),
              ],
              onChanged: (v) => setState(() => _segment = v),
            ),
            const SizedBox(height: 12),
            PmStepperField(
              valueLabel: '$_stepperMin min',
              onDecrement: () => setState(() {
                if (_stepperMin > 5) _stepperMin -= 5;
              }),
              onIncrement: () => setState(() => _stepperMin += 5),
            ),
            const SizedBox(height: 12),
            PmWhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text('Session toggle', style: AppTypography.body16),
                  ),
                  PmSwitch(
                    value: _toggle,
                    onChanged: (v) => setState(() => _toggle = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const PmSectionHeader(title: 'Feedback & Empty States'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                PmSecondaryButton(
                  label: 'Open confirmation',
                  fullWidth: false,
                  size: PmButtonSize.medium,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => PmConfirmationDialog(
                      icon: Icons.check_rounded,
                      title: 'Finish this session?',
                      message: 'You studied 20m in this focus session.',
                      confirmLabel: 'Finish Session',
                      onConfirm: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                PmSecondaryButton(
                  label: 'Open bottom sheet',
                  fullWidth: false,
                  size: PmButtonSize.medium,
                  onPressed: () => PmBottomSheet.show<void>(
                    context: context,
                    title: 'Session notes',
                    child: const PmTextArea(
                      label: 'Notes',
                      hintText: 'Add a note for this session',
                    ),
                  ),
                ),
                PmPrimaryButton(
                  label: 'Show toast',
                  fullWidth: false,
                  size: PmButtonSize.medium,
                  onPressed: () => PmToast.show(context, 'Changes saved'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PmEmptyState(
              icon: Icons.history_rounded,
              title: 'No sessions yet',
              subtitle: 'Finish a study session to see it here',
              actionLabel: 'Start studying',
              actionIcon: Icons.add_rounded,
              onAction: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: PmBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}
