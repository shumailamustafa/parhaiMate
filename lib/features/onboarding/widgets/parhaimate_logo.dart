import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// ParhaiMate square-rounded app icon rendered from assets/app-icon.png.
class ParhaiMateLogo extends StatelessWidget {
  const ParhaiMateLogo({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Image.asset(
          'assets/app-icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
