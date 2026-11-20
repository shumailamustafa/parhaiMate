import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Interactive screen directory matching Navigation Flow.png (without notifications).
class NavigationFlowView extends StatelessWidget {
  const NavigationFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = <_NavGroup>[
      _NavGroup(
        title: 'Launch & onboarding',
        items: <_NavEntry>[
          _NavEntry('Splash Screen', AppRoutes.splash),
          _NavEntry('Onboarding', AppRoutes.onboarding),
          _NavEntry('Home Dashboard', AppRoutes.home, replaceRoot: true),
        ],
      ),
      _NavGroup(
        title: 'Timer & session',
        items: <_NavEntry>[
          _NavEntry('Study Timer', AppRoutes.timer),
          _NavEntry('Session Setup', AppRoutes.sessionSetup),
          _NavEntry('Active Focus Mode', AppRoutes.activeFocus),
          _NavEntry('Session Summary', AppRoutes.sessionSummary),
        ],
      ),
      _NavGroup(
        title: 'Subjects & planner',
        items: <_NavEntry>[
          _NavEntry('My Subjects', AppRoutes.subjects),
          _NavEntry('Add Subject', AppRoutes.addSubject),
          _NavEntry('Study Planner', AppRoutes.planner),
          _NavEntry('Add Study Task', AppRoutes.addTask),
          _NavEntry('Calendar', AppRoutes.calendar),
        ],
      ),
      _NavGroup(
        title: 'Progress & milestones',
        items: <_NavEntry>[
          _NavEntry('Study Statistics', AppRoutes.progress),
          _NavEntry('Session History', AppRoutes.sessionHistory),
          _NavEntry('Goals & Streaks', AppRoutes.goals),
          _NavEntry('Achievements', AppRoutes.achievements),
        ],
      ),
      _NavGroup(
        title: 'Settings & backup',
        items: <_NavEntry>[
          _NavEntry('Settings', AppRoutes.settings),
          _NavEntry('Daily Study Goal', AppRoutes.dailyGoalConfig),
          _NavEntry('Weekly Study Goal', AppRoutes.weeklyGoalConfig),
          _NavEntry('Timer Presets', AppRoutes.timerPresets),
          _NavEntry('Create Timer Preset', AppRoutes.createPreset),
          _NavEntry('Export Backup', AppRoutes.exportBackup),
          _NavEntry('Import Backup', AppRoutes.importBackup),
          _NavEntry('Export Study Report', AppRoutes.studyReport),
          _NavEntry('Privacy Policy', AppRoutes.privacyPolicy),
        ],
      ),
      _NavGroup(
        title: 'Design system',
        items: <_NavEntry>[
          _NavEntry('Component Library', AppRoutes.components),
        ],
      ),
    ];

    return Scaffold(
      appBar: const PmAppBar(title: 'Navigation Flow'),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                group.title.toUpperCase(),
                style: AppTypography.meta12SemiBold.copyWith(
                  letterSpacing: 0.7,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              PmWhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: List<Widget>.generate(group.items.length, (i) {
                    final item = group.items[i];
                    return Column(
                      children: <Widget>[
                        PmListTileRow(
                          title: item.label,
                          trailingValue: item.route,
                          onTap: () {
                            if (item.replaceRoot) {
                              Get.offAllNamed<void>(item.route);
                            } else {
                              Get.toNamed<void>(item.route);
                            }
                          },
                        ),
                        if (i < group.items.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavGroup {
  const _NavGroup({required this.title, required this.items});

  final String title;
  final List<_NavEntry> items;
}

class _NavEntry {
  const _NavEntry(this.label, this.route, {this.replaceRoot = false});

  final String label;
  final String route;
  final bool replaceRoot;
}
