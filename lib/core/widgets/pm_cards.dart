import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Light grey (#F0F0F0) information card with 16px rounded corners.
class PmGreyCard extends StatelessWidget {
  const PmGreyCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.cardPaddingLarge),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.cardRadius,
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Pure white (#FFFFFF) card with subtle 1px #E4E4E4 border and 16px corners.
class PmWhiteCard extends StatelessWidget {
  const PmWhiteCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderColor = AppColors.border,
    this.borderWidth = AppSpacing.borderWidth,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardRadius,
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Section heading with optional navy action link or right-aligned meta label.
class PmSectionHeader extends StatelessWidget {
  const PmSectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onActionTap,
    this.trailingMeta,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final String? trailingMeta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppTypography.section18,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          InkWell(
            borderRadius: AppRadii.controlRadius,
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                actionLabel!,
                style: AppTypography.secondary14SemiBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else if (trailingMeta != null)
          Text(trailingMeta!, style: AppTypography.meta12Medium),
      ],
    );
  }
}

/// Consistent list row with 64px min height, 16px horizontal padding.
class PmListTileRow extends StatelessWidget {
  const PmListTileRow({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingValue,
    this.showChevron = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 12,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? trailingValue;
  final bool showChevron;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.listRowMinHeight),
        child: Padding(
          padding: padding,
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.body16Medium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.secondary14,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...<Widget>[
                if (trailingValue != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Text(
                    trailingValue!,
                    style: AppTypography.secondary14Medium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (showChevron) ...<Widget>[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
