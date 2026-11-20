import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../widgets/parhaimate_logo.dart';

/// Launch screen matching 01 Splash.png.
class SplashView extends GetView<SplashViewModel> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ParhaiMateLogo(size: 78),
                  SizedBox(height: 22),
                  Text(
                    'ParhaiMate',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Personal Study Companion',
                    style: AppTypography.body16,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Obx(() {
              final error = controller.errorMessage.value;
              if (error != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: <Widget>[
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: AppTypography.secondary14,
                      ),
                      const SizedBox(height: 12),
                      PmPrimaryButton(
                        label: 'Try Again',
                        onPressed: () => unawaited(controller.retry()),
                      ),
                    ],
                  ),
                );
              }
              final active = controller.activeDot.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(3, (index) {
                  final color = index == active
                      ? AppColors.primary
                      : (index == (active + 1) % 3
                          ? AppColors.textMuted
                          : AppColors.track);
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 24),
            const PoweredByCodingDistrict(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
