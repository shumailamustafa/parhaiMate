import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parhaimate/core/theme/theme.dart';
import 'package:parhaimate/core/widgets/widgets.dart';
import 'package:parhaimate/shared/enums/subject_visuals.dart';
import 'package:parhaimate/shared/widgets/widgets.dart';

void main() {
  group('Stage 2 Design Tokens & Strict Palette', () {
    test('color palette matches approved monochrome and navy tokens', () {
      expect(AppColors.background, const Color(0xFFFFFFFF));
      expect(AppColors.foreground, const Color(0xFF000000));
      expect(AppColors.primary, const Color(0xFF123B52));
      expect(AppColors.onPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.surface, const Color(0xFFF0F0F0));
      expect(AppColors.card, const Color(0xFFFFFFFF));
      expect(AppColors.border, const Color(0xFFE4E4E4));
      expect(AppColors.divider, const Color(0xFFEDEDED));
      expect(AppColors.track, const Color(0xFFDCDCDC));
      expect(AppColors.disabled, const Color(0xFFC8C8C8));
      expect(AppColors.destructive, const Color(0xFF000000));

      // Verify chart palette only uses navy (#123B52), black, and neutral greys.
      for (final color in AppColors.chartPalette) {
        final isNavy = color == AppColors.primary;
        final isGreyOrBlack =
            color.r == color.g && color.g == color.b;
        expect(isNavy || isGreyOrBlack, isTrue);
      }
    });

    test('typography scale and theme follow V1 specification', () {
      expect(AppTypography.timer68.fontSize, 68);
      expect(AppTypography.display32.fontSize, 32);
      expect(AppTypography.title24.fontSize, 24);
      expect(AppTypography.section18.fontSize, 18);
      expect(AppTypography.body16.fontSize, 16);
      expect(AppTypography.secondary14.fontSize, 14);
      expect(AppTypography.meta12.fontSize, 12);

      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  group('Stage 2 Reusable Component Library', () {
    testWidgets('buttons render sizes, disabled, loading, and tap callbacks',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: <Widget>[
                PmPrimaryButton(
                  label: 'Primary',
                  onPressed: () => tapped++,
                ),
                const PmPrimaryButton(
                  label: 'Disabled',
                  onPressed: null,
                ),
                PmPrimaryButton(
                  label: 'Loading',
                  isLoading: true,
                  onPressed: () => tapped++,
                ),
                PmSecondaryButton(
                  label: 'Secondary',
                  size: PmButtonSize.medium,
                  onPressed: () => tapped++,
                ),
                PmDestructiveButton(
                  label: 'Delete history',
                  onPressed: () => tapped++,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Primary'));
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.text('Secondary'));
      await tester.tap(find.text('Delete history'));
      expect(tapped, 3);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('text field shows inline validation error state',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: PmTextField(
                label: 'Subject name',
                hintText: 'Add a subject',
                errorText: 'Enter a subject name',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Subject name'), findsOneWidget);
      expect(find.text('Enter a subject name'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('segmented control, stepper, and bottom nav respond to taps',
        (tester) async {
      var period = 'Week';
      var minutes = 25;
      var navIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: <Widget>[
                    PmSegmentedControl<String>(
                      selectedValue: period,
                      options: const <PmSegmentOption<String>>[
                        PmSegmentOption(value: 'Week', label: 'Week'),
                        PmSegmentOption(value: 'Month', label: 'Month'),
                        PmSegmentOption(value: 'Year', label: 'Year'),
                      ],
                      onChanged: (val) => setState(() => period = val),
                    ),
                    PmStepperField(
                      valueLabel: '$minutes min',
                      onDecrement: () => setState(() => minutes -= 5),
                      onIncrement: () => setState(() => minutes += 5),
                    ),
                  ],
                ),
                bottomNavigationBar: PmBottomNav(
                  currentIndex: navIndex,
                  onTap: (idx) => setState(() => navIndex = idx),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Month'));
      await tester.pump();
      expect(period, 'Month');

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.text('30 min'), findsOneWidget);

      await tester.tap(find.text('Subjects'));
      await tester.pump();
      expect(navIndex, 2);
    });

    testWidgets(
        'domain cards, progress indicators, and empty state render cleanly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const PmProgressBar(progress: 0.63),
                  const PmCircularProgress(
                    progress: 0.63,
                    child: Text('63%'),
                  ),
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
                  TimerModeCard(
                    mode: TimerMode.focus,
                    metaText: '25 min',
                    description: 'Stay focused for a set amount of time.',
                    selected: true,
                    onTap: () {},
                  ),
                  const AchievementCard(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Time Master',
                    description: 'Complete 50 hours of study.',
                    unlocked: false,
                    progress: 0.9,
                    progressLabel: '45 of 50 hours',
                  ),
                  PmEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No sessions yet',
                    subtitle: 'Finish a study session to see it here',
                    actionLabel: 'Start studying',
                    onAction: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('63%'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Focus Timer'), findsOneWidget);
      expect(find.text('Time Master'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);
    });
  });
}
