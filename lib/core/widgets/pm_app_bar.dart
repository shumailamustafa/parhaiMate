import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Standard 56px top app bar with pure white surface and dark back button.
class PmAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PmAppBar({
    required this.title,
    super.key,
    this.showBack = true,
    this.onBack,
    this.leading,
    this.actions,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && showBack && canPop) {
      resolvedLeading = IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        color: AppColors.textPrimary,
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: AppSpacing.appBarHeight,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      titleSpacing: resolvedLeading == null ? AppSpacing.screenPadding : 4,
      title: Text(
        title,
        style: AppTypography.section18,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions != null
          ? <Widget>[
              ...actions!,
              const SizedBox(width: AppSpacing.md),
            ]
          : null,
    );
  }
}
