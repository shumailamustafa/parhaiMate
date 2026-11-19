import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pm_buttons.dart';
import 'pm_cards.dart';

/// Standard 24px rounded confirmation dialog matching all ParhaiMate dialogs.
class PmConfirmationDialog extends StatelessWidget {
  const PmConfirmationDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    super.key,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.confirmEnabled = true,
    this.bodyExtra,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;
  final bool confirmEnabled;
  final Widget? bodyExtra;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.section18.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.secondary14),
            if (bodyExtra != null) ...<Widget>[
              const SizedBox(height: 16),
              bodyExtra!,
            ],
            const SizedBox(height: 24),
            if (isDestructive)
              PmDestructiveButton(
                label: confirmLabel,
                onPressed: confirmEnabled ? onConfirm : null,
              )
            else
              PmPrimaryButton(
                label: confirmLabel,
                onPressed: confirmEnabled ? onConfirm : null,
              ),
            const SizedBox(height: 8),
            Center(
              child: PmGhostButton(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard 24px top-rounded bottom sheet container with drag handle and close icon.
class PmBottomSheet extends StatelessWidget {
  const PmBottomSheet({
    required this.title,
    required this.child,
    super.key,
    this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      barrierColor: AppColors.barrierScrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetTopRadius),
      builder: (_) => PmBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.track,
                    borderRadius: AppRadii.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(title, style: AppTypography.section18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textPrimary,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable empty state card matching Component Library & Empty States screenshots.
class PmEmptyState extends StatelessWidget {
  const PmEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.ghostActionLabel,
    this.onGhostAction,
    this.wrappedInCard = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? ghostActionLabel;
  final VoidCallback? onGhostAction;
  final bool wrappedInCard;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.section18,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.secondary14,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 18),
            PmPrimaryButton(
              label: actionLabel!,
              icon: actionIcon,
              fullWidth: false,
              size: PmButtonSize.medium,
              onPressed: onAction,
            ),
          ],
          if (ghostActionLabel != null && onGhostAction != null) ...<Widget>[
            const SizedBox(height: 12),
            PmGhostButton(
              label: ghostActionLabel!,
              onPressed: onGhostAction,
              compact: true,
            ),
          ],
        ],
      ),
    );

    if (!wrappedInCard) {
      return Center(child: content);
    }

    return SizedBox(
      width: double.infinity,
      child: PmWhiteCard(padding: EdgeInsets.zero, child: content),
    );
  }
}

/// Centered monochrome/navy loading state.
class PmLoadingState extends StatelessWidget {
  const PmLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                message!,
                style: AppTypography.secondary14,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Monochrome error state card with optional retry action.
class PmErrorState extends StatelessWidget {
  const PmErrorState({
    required this.title,
    required this.message,
    super.key,
    this.retryLabel = 'Try Again',
    this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PmEmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      subtitle: message,
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
    );
  }
}

/// Navy pill toast helper for status feedback.
abstract final class PmToast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.secondary14Medium.copyWith(
              color: AppColors.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
