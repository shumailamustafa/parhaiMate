import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pm_cards.dart';
import '../../core/widgets/pm_inputs.dart';
import '../../core/widgets/pm_progress.dart';
import '../enums/subject_visuals.dart';

/// Tiny geometric navy glyph placed beside subject names in cards and planner.
class SubjectIdentifierBadge extends StatelessWidget {
  const SubjectIdentifierBadge({
    required this.identifier,
    super.key,
    this.size = 8,
    this.color = AppColors.primary,
  });

  final SubjectIdentifier identifier;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainter(identifier: identifier, color: color),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.identifier, required this.color});

  final SubjectIdentifier identifier;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    switch (identifier) {
      case SubjectIdentifier.circle:
        canvas.drawCircle(Offset(cx, cy), r, fill);
      case SubjectIdentifier.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
            const Radius.circular(1.5),
          ),
          fill,
        );
      case SubjectIdentifier.triangle:
        final path = Path()
          ..moveTo(cx, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, fill);
      case SubjectIdentifier.diamond:
        final path = Path()
          ..moveTo(cx, 0)
          ..lineTo(size.width, cy)
          ..lineTo(cx, size.height)
          ..lineTo(0, cy)
          ..close();
        canvas.drawPath(path, fill);
      case SubjectIdentifier.ring:
        final stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(Offset(cx, cy), r - 0.8, stroke);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) {
    return oldDelegate.identifier != identifier || oldDelegate.color != color;
  }
}

/// 40x40 rounded icon badge for subjects (grey or selected navy fill).
class SubjectIconBox extends StatelessWidget {
  const SubjectIconBox({
    required this.iconKey,
    super.key,
    this.size = AppSpacing.iconBoxSize,
    this.iconSize = 20,
    this.selected = false,
    this.backgroundColor,
    this.iconColor,
  });

  final SubjectIconKey iconKey;
  final double size;
  final double iconSize;
  final bool selected;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bg =
        backgroundColor ?? (selected ? AppColors.primary : AppColors.surface);
    final fg =
        iconColor ?? (selected ? AppColors.onPrimary : AppColors.primary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(iconKey.iconData, size: iconSize, color: fg),
    );
  }
}

/// Subject card matching My Subjects & Component Library reference screens.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    required this.name,
    required this.iconKey,
    required this.identifier,
    required this.totalLabel,
    required this.weekStudiedLabel,
    required this.weekTargetLabel,
    required this.weekProgress,
    required this.onTap,
    super.key,
  });

  final String name;
  final SubjectIconKey iconKey;
  final SubjectIdentifier identifier;
  final String totalLabel;
  final String weekStudiedLabel;
  final String weekTargetLabel;
  final double weekProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PmWhiteCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SubjectIconBox(iconKey: iconKey, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SubjectIdentifierBadge(identifier: identifier),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.body16SemiBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalLabel,
                      style: AppTypography.secondary14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('This week', style: AppTypography.secondary14),
              ),
              RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: weekStudiedLabel,
                      style: AppTypography.secondary14SemiBold,
                    ),
                    TextSpan(
                      text: ' / $weekTargetLabel',
                      style: AppTypography.secondary14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PmProgressBar(progress: weekProgress, height: 6),
        ],
      ),
    );
  }
}

/// Study session history row matching Home Recent Activity & Session History.
class StudySessionRow extends StatelessWidget {
  const StudySessionRow({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.icon,
    super.key,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String durationLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: 12,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.body16SemiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.secondary14,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(durationLabel, style: AppTypography.secondary14SemiBold),
          ],
        ),
      ),
    );
  }
}

/// Standalone white study session card (Component Library variant).
class StudySessionCard extends StatelessWidget {
  const StudySessionCard({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.icon,
    super.key,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String durationLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PmWhiteCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: StudySessionRow(
        title: title,
        subtitle: subtitle,
        durationLabel: durationLabel,
        icon: icon,
      ),
    );
  }
}

/// Planner task card matching Study Planner, Calendar, and Home Schedule.
class PlannerTaskCard extends StatelessWidget {
  const PlannerTaskCard({
    required this.title,
    required this.metaLabel,
    required this.durationLabel,
    required this.isCompleted,
    required this.onToggleComplete,
    super.key,
    this.subjectIdentifier,
    this.onTap,
    this.wrappedInCard = true,
  });

  final String title;
  final String metaLabel;
  final String durationLabel;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final SubjectIdentifier? subjectIdentifier;
  final VoidCallback? onTap;
  final bool wrappedInCard;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      borderRadius: wrappedInCard ? AppRadii.cardRadius : BorderRadius.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: <Widget>[
            PmCheckCircle(checked: isCompleted, onTap: onToggleComplete),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.body16Medium.copyWith(
                      color: isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      if (subjectIdentifier != null) ...<Widget>[
                        SubjectIdentifierBadge(identifier: subjectIdentifier!),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          metaLabel,
                          style: AppTypography.secondary14,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              durationLabel,
              style: AppTypography.secondary14SemiBold.copyWith(
                color: isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    if (!wrappedInCard) {
      return row;
    }

    return PmWhiteCard(padding: EdgeInsets.zero, child: row);
  }
}

/// Statistics metric card (light grey or white bordered) matching Component Library.
class StatisticsMetricCard extends StatelessWidget {
  const StatisticsMetricCard({
    required this.label,
    required this.value,
    super.key,
    this.caption,
    this.isPrimarySurface = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool isPrimarySurface;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.secondary14,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.title24.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: AppTypography.meta12,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (isPrimarySurface) {
      return PmGreyCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: content,
      );
    }
    return PmWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: content,
    );
  }
}

/// Selectable timer mode card matching Study Timer reference screenshot.
class TimerModeCard extends StatelessWidget {
  const TimerModeCard({
    required this.mode,
    required this.metaText,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final TimerMode mode;
  final String metaText;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.card : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardRadius,
        side: selected
            ? const BorderSide(color: AppColors.primary, width: 1.4)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mode.iconData,
                  size: 22,
                  color: selected ? AppColors.onPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            mode.label,
                            style: AppTypography.body16SemiBold,
                          ),
                        ),
                        Text(metaText, style: AppTypography.secondary14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.secondary14,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          width: selected ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

/// Achievement milestone card matching Achievements screen & Component Library.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
    super.key,
    this.progress = 0,
    this.progressLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool unlocked;
  final double progress;
  final String? progressLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? AppColors.primary : AppColors.card,
              ),
              child: Icon(
                icon,
                size: 20,
                color: unlocked ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
                  size: 13,
                  color:
                      unlocked ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  unlocked ? 'Unlocked' : 'Locked',
                  style: AppTypography.meta12SemiBold.copyWith(
                    color:
                        unlocked ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTypography.body16SemiBold,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTypography.secondary14,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (!unlocked && progressLabel != null) ...<Widget>[
          const SizedBox(height: 12),
          PmProgressBar(progress: progress, height: 5),
          const SizedBox(height: 6),
          Text(progressLabel!, style: AppTypography.meta12),
        ],
      ],
    );

    if (unlocked) {
      return PmWhiteCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        onTap: onTap,
        child: content,
      );
    }

    return PmGreyCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      onTap: onTap,
      child: content,
    );
  }
}
