import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum PmButtonSize { large, medium, small }

enum PmIconButtonVariant { outlined, grey, navy, plain }

double _heightForSize(PmButtonSize size) {
  switch (size) {
    case PmButtonSize.large:
      return AppSpacing.buttonLargeHeight;
    case PmButtonSize.medium:
      return AppSpacing.buttonMediumHeight;
    case PmButtonSize.small:
      return AppSpacing.buttonSmallHeight;
  }
}

EdgeInsetsGeometry _paddingForSize(PmButtonSize size) {
  switch (size) {
    case PmButtonSize.large:
      return const EdgeInsets.symmetric(horizontal: 20);
    case PmButtonSize.medium:
      return const EdgeInsets.symmetric(horizontal: 16);
    case PmButtonSize.small:
      return const EdgeInsets.symmetric(horizontal: 12);
  }
}

/// Navy (#123B52) primary button with optional icon, loading, and disabled states.
class PmPrimaryButton extends StatelessWidget {
  const PmPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.size = PmButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final PmButtonSize size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final height = _heightForSize(size);
    final textStyle = (size == PmButtonSize.small
            ? AppTypography.secondary14SemiBold
            : AppTypography.body16SemiBold)
        .copyWith(color: AppColors.onPrimary);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: enabled ? AppColors.primary : AppColors.disabled,
        borderRadius: AppRadii.controlRadius,
        child: InkWell(
          borderRadius: AppRadii.controlRadius,
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: _paddingForSize(size),
            child: Center(
              widthFactor: fullWidth ? null : 1,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, size: 18, color: AppColors.onPrimary),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: textStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary white button with subtle #E4E4E4 border and pure black label.
class PmSecondaryButton extends StatelessWidget {
  const PmSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.size = PmButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final PmButtonSize size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final height = _heightForSize(size);
    final fg = enabled ? AppColors.textPrimary : AppColors.textMuted;
    final textStyle = (size == PmButtonSize.small
            ? AppTypography.secondary14SemiBold
            : AppTypography.body16SemiBold)
        .copyWith(color: fg);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.controlRadius,
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: AppRadii.controlRadius,
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: _paddingForSize(size),
            child: Center(
              widthFactor: fullWidth ? null : 1,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, size: 18, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: textStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pure black destructive action button (matches Delete / Clear dialogs).
class PmDestructiveButton extends StatelessWidget {
  const PmDestructiveButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.buttonLargeHeight,
      child: Material(
        color: enabled ? AppColors.destructive : AppColors.disabled,
        borderRadius: AppRadii.controlRadius,
        child: InkWell(
          borderRadius: AppRadii.controlRadius,
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              widthFactor: fullWidth ? null : 1,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, size: 18, color: AppColors.onPrimary),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.body16SemiBold.copyWith(
                              color: AppColors.onPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navy text link / ghost action button.
class PmGhostButton extends StatelessWidget {
  const PmGhostButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadii.controlRadius,
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 12,
          vertical: compact ? 6 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: (compact
                      ? AppTypography.secondary14SemiBold
                      : AppTypography.body16SemiBold)
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44x44 circular icon button (outlined white, light grey, navy +, or plain).
class PmIconButton extends StatelessWidget {
  const PmIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.variant = PmIconButtonVariant.outlined,
    this.tooltip,
    this.size = AppSpacing.minTouchTarget,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final PmIconButtonVariant variant;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case PmIconButtonVariant.outlined:
        bgColor = AppColors.card;
        fgColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.border);
      case PmIconButtonVariant.grey:
        bgColor = AppColors.surface;
        fgColor = AppColors.textPrimary;
      case PmIconButtonVariant.navy:
        bgColor = AppColors.primary;
        fgColor = AppColors.onPrimary;
      case PmIconButtonVariant.plain:
        bgColor = Colors.transparent;
        fgColor = AppColors.textPrimary;
    }

    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: bgColor,
        shape: CircleBorder(side: side),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, size: iconSize, color: fgColor),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}
