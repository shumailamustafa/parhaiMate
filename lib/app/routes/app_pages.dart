import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/timer_engine_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/repositories/repositories.dart';
import '../../features/onboarding/viewmodels/onboarding_viewmodel.dart';
import '../../features/onboarding/viewmodels/splash_viewmodel.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/onboarding/views/splash_view.dart';
import '../../features/settings/views/component_library_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<void>(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SplashViewModel>(
          () => SplashViewModel(
            settingsRepository: Get.find<SettingsRepository>(),
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<OnboardingViewModel>(
          () => OnboardingViewModel(Get.find<SettingsRepository>()),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.components,
      page: () => const ComponentLibraryView(),
    ),
    // Section 5.1 initial home shell preview (replaced in Section 5.2).
    GetPage<void>(
      name: AppRoutes.home,
      page: () => const _Section51HomePreview(),
    ),
    GetPage<void>(
      name: AppRoutes.activeFocus,
      page: () => const _Section51HomePreview(),
    ),
  ];
}

class _Section51HomePreview extends StatelessWidget {
  const _Section51HomePreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PmAppBar(title: 'ParhaiMate', showBack: false),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const PmGreyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Section 5.1 Ready', style: AppTypography.section18),
                  SizedBox(height: 8),
                  Text(
                    'Onboarding completed. Use the actions below to inspect the Design System Component Library or replay Onboarding.',
                    style: AppTypography.secondary14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PmPrimaryButton(
              label: 'Open Component Library',
              icon: Icons.widgets_outlined,
              onPressed: () => Get.toNamed<void>(AppRoutes.components),
            ),
            const SizedBox(height: 12),
            PmSecondaryButton(
              label: 'Replay Onboarding',
              icon: Icons.refresh_rounded,
              onPressed: () => Get.offAllNamed<void>(AppRoutes.onboarding),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PmBottomNav(
        currentIndex: 0,
        onTap: (_) {},
      ),
      backgroundColor: AppColors.background,
    );
  }
}
