import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/onboarding_illustrations.dart';

/// 3-slide onboarding flow matching 02 Onboarding reference screenshots.
class OnboardingView extends GetView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.completeOnboarding,
                  child: Text(
                    'Skip',
                    style: AppTypography.secondary14SemiBold.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: OnboardingViewModel.slides.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  final slide = OnboardingViewModel.slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OnboardingIllustration(slideIndex: index),
                        const SizedBox(height: 36),
                        Text(
                          slide.title,
                          style: AppTypography.title24,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            slide.subtitle,
                            style: AppTypography.body16.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Obx(() {
              final current = controller.currentIndex.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  OnboardingViewModel.slides.length,
                  (index) {
                    final active = index == current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.track,
                        borderRadius: AppRadii.pillRadius,
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              child: Obx(
                () => PmPrimaryButton(
                  label: controller.isLastSlide ? 'Get Started' : 'Next',
                  isLoading: controller.isSubmitting.value,
                  onPressed: controller.onNextOrGetStarted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
