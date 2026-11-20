import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Company attribution footer rendered on Splash & Settings screens.
class PoweredByCodingDistrict extends StatelessWidget {
  const PoweredByCodingDistrict({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Powered by Coding District',
          style: AppTypography.meta12Medium,
        ),
        const SizedBox(width: 8),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/Coding District Icn.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
