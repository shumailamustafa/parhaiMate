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
import '../viewmodels/achievements_viewmodel.dart';

/// Achievements screen matching 14 Achievements.png & detail bottom sheets.
class AchievementsView extends GetView<AchievementsViewModel> {
  const AchievementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Achievements'),
      body: Obx(() {
        if (controller.isLoading.value && controller.achievements.isEmpty) {
          return const PmLoadingState(message: 'Loading achievements...');
        }

        final items = controller.achievements;
        final unlocked = controller.unlockedCount;
        final total = controller.totalCount;
        final pct = controller.unlockedPercent;
        final rowsCount = (items.length / 2).ceil();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            8,
            AppSpacing.screenPadding,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Every session brings you closer.',
                style: AppTypography.secondary14,
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '$unlocked of $total unlocked',
                      style: AppTypography.body16SemiBold,
                    ),
                  ),
                  Text('$pct%', style: AppTypography.secondary14),
                ],
              ),
              const SizedBox(height: 8),
              PmProgressBar(progress: controller.overallProgress, height: 7),
              const SizedBox(height: 20),
              ...List<Widget>.generate(rowsCount, (rowIdx) {
                final firstIdx = rowIdx * 2;
                final secondIdx = firstIdx + 1;
                final first = items[firstIdx];
                final second = secondIdx < items.length ? items[secondIdx] : null;

                return Padding(
                  padding: EdgeInsets.only(bottom: rowIdx < rowsCount - 1 ? 12 : 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: _buildCard(context, first),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: second != null
                              ? _buildCard(context, second)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCard(BuildContext context, AchievementEntity a) {
    return AchievementCard(
      icon: controller.iconForAchievement(a.code),
      title: a.title,
      description: a.description,
      unlocked: a.isUnlocked,
      progress: a.progress,
      progressLabel: controller.progressLabelFor(a),
      onTap: () => _showDetailSheet(context, a),
    );
  }

  Future<void> _showDetailSheet(BuildContext context, AchievementEntity a) {
    final icon = controller.iconForAchievement(a.code);
    final pct = (a.progress * 100).round();

    return PmBottomSheet.show<void>(
      context: context,
      title: a.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: a.isUnlocked ? AppColors.primary : AppColors.surface,
              ),
              child: Icon(
                icon,
                size: 32,
                color: a.isUnlocked ? AppColors.onPrimary : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            a.description,
            style: AppTypography.secondary14,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (a.isUnlocked) ...<Widget>[
            PmGreyCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Center(
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Unlocked',
                      style: AppTypography.body16SemiBold,
                    ),
                    if (a.unlockedAtMs != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        DateTimeUtils.formatShortDate(
                          DateTime.fromMillisecondsSinceEpoch(
                            a.unlockedAtMs!,
                            isUtc: true,
                          ),
                        ),
                        style: AppTypography.meta12,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...<Widget>[
            PmGreyCard(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          controller.progressLabelFor(a),
                          style: AppTypography.body16SemiBold,
                        ),
                      ),
                      Text('$pct%', style: AppTypography.secondary14),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PmProgressBar(progress: a.progress, height: 7),
                  const SizedBox(height: 8),
                  Text(
                    controller.remainingLabelFor(a),
                    style: AppTypography.secondary14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PmPrimaryButton(
              label: 'Start Studying',
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed<void>(AppRoutes.sessionSetup);
              },
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: PmGhostButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
