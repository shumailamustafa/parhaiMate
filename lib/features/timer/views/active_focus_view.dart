import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/active_focus_viewmodel.dart';

/// Distraction-free Active Focus timer screen matching 06 Active Focus.png & variants.
class ActiveFocusView extends GetView<ActiveFocusViewModel> {
  const ActiveFocusView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.minimizeToHome();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                final active = controller.active;
                if (active == null) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 24),
                            onPressed: controller.minimizeToHome,
                          ),
                        ),
                        Expanded(
                          child: PmEmptyState(
                            icon: Icons.timer_outlined,
                            title: 'No active study session',
                            subtitle:
                                'Start a Focus Timer, Stopwatch, or Pomodoro session whenever you are ready.',
                            actionLabel: 'Set Up Session',
                            onAction: () =>
                                Get.offNamed<void>(AppRoutes.sessionSetup),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isPaused = active.isPaused;
                final isStopwatch = active.timerMode == TimerMode.stopwatch;
                final isPomodoro = active.timerMode == TimerMode.pomodoro;
                final dotColor =
                    isPaused ? AppColors.textSecondary : AppColors.primary;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    8,
                    AppSpacing.screenPadding,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight - 32),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    tooltip: 'Minimize session',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 24,
                                      color: AppColors.textPrimary,
                                    ),
                                    onPressed: controller.minimizeToHome,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 52,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          SubjectIdentifierBadge(
                                            identifier:
                                                controller.subjectIdentifier,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              controller.subjectName,
                                              style:
                                                  AppTypography.body16SemiBold,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.modeLabel,
                                        style: AppTypography.secondary14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(child: SizedBox(height: 20)),
                          PmCircularProgress(
                            size: 260,
                            strokeWidth: 12,
                            progress: controller.timerEngine.progress.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  controller.timerClockText,
                                  style: AppTypography.timer68,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  controller.ringCaption,
                                  style: AppTypography.secondary14,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isStopwatch)
                            Text(
                              controller.startedAtLabel,
                              style: AppTypography.body16Medium,
                            )
                          else ...<Widget>[
                            Text(
                              '${controller.elapsedFocusMinutes} of ${controller.totalPlannedFocusMinutes} min',
                              style: AppTypography.body16Medium,
                            ),
                            if (isPomodoro) ...<Widget>[
                              const SizedBox(height: 12),
                              _PomodoroCycleIndicators(active: active),
                              const SizedBox(height: 8),
                              Text(
                                'Cycle ${active.currentCycle} of ${active.totalCycles}',
                                style: AppTypography.secondary14,
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                controller.statusLabel,
                                style: AppTypography.body16.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Expanded(child: SizedBox(height: 20)),
                          PmIconButton(
                            size: 72,
                            iconSize: 32,
                            variant: PmIconButtonVariant.navy,
                            tooltip:
                                isPaused ? 'Resume timer' : 'Pause timer',
                            icon: isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            onPressed: controller.togglePauseResume,
                          ),
                          const SizedBox(height: 22),
                          PmSecondaryButton(
                            label: 'Finish Session',
                            isLoading: controller.isSubmitting.value,
                            onPressed: () => _showFinishConfirmation(context),
                          ),
                          const SizedBox(height: 10),
                          PmGhostButton(
                            label: 'Cancel Session',
                            onPressed: controller.isSubmitting.value
                                ? null
                                : () => _showCancelConfirmation(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showFinishConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.check_rounded,
        title: 'Finish this session?',
        message:
            "You've studied ${controller.studiedDurationForDialog}. It'll be saved to ${controller.subjectName}.",
        confirmLabel: 'Finish Session',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed ?? false) {
      await controller.finishSessionEarly();
    }
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.close_rounded,
        title: 'Cancel this session?',
        message:
            "Your ${controller.studiedDurationForDialog} of study won't be saved. You can't undo this.",
        confirmLabel: 'Cancel Session',
        cancelLabel: 'Keep Studying',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed ?? false) {
      await controller.cancelSession();
    }
  }
}

class _PomodoroCycleIndicators extends StatelessWidget {
  const _PomodoroCycleIndicators({required this.active});

  final ActiveTimerEntity active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(active.totalCycles, (index) {
        final cycleNumber = index + 1;
        final isCompleted = cycleNumber < active.currentCycle ||
            (cycleNumber == active.currentCycle &&
                active.phase != TimerPhase.focusing);
        final isCurrentFocus = cycleNumber == active.currentCycle &&
            active.phase == TimerPhase.focusing;

        return Padding(
          padding: EdgeInsets.only(right: index < active.totalCycles - 1 ? 8 : 0),
          child: Container(
            width: 28,
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : (isCurrentFocus ? AppColors.card : AppColors.track),
              borderRadius: AppRadii.pillRadius,
              border: isCurrentFocus
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
