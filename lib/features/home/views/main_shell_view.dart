import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../statistics/views/statistics_view.dart';
import '../../subjects/views/subjects_view.dart';
import '../../timer/views/study_timer_view.dart';
import '../viewmodels/main_shell_viewmodel.dart';
import 'home_view.dart';

/// Persistent 4-tab navigation shell hosting Home, Timer, Subjects, and Progress.
class MainShellView extends GetView<MainShellViewModel> {
  const MainShellView({
    super.key,
    this.timerTabBuilder,
    this.subjectsTabBuilder,
    this.progressTabBuilder,
  });

  final WidgetBuilder? timerTabBuilder;
  final WidgetBuilder? subjectsTabBuilder;
  final WidgetBuilder? progressTabBuilder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;
      final hasActiveSession = controller.timerEngine.hasActiveSession;
      final activeSeconds = controller.timerEngine.displaySeconds.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: <Widget>[
            if (hasActiveSession)
              SafeArea(
                bottom: false,
                child: Material(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: () => Get.toNamed<void>(AppRoutes.activeFocus),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: AppColors.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Active study session · ${DateTimeUtils.formatTimerClock(activeSeconds)}',
                              style: AppTypography.secondary14SemiBold.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Resume',
                            style: AppTypography.secondary14SemiBold.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: index,
                children: <Widget>[
                  const HomeView(),
                  timerTabBuilder?.call(context) ?? const StudyTimerView(),
                  subjectsTabBuilder?.call(context) ?? const SubjectsView(),
                  progressTabBuilder?.call(context) ?? const StatisticsView(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: PmBottomNav(
          currentIndex: index,
          onTap: controller.changeTab,
        ),
      );
    });
  }
}
