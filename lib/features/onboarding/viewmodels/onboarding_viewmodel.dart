import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../domain/repositories/repositories.dart';

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class OnboardingViewModel extends GetxController {
  OnboardingViewModel(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  late final PageController pageController;
  final RxInt currentIndex = 0.obs;
  final RxBool isSubmitting = false.obs;

  static const List<OnboardingSlideData> slides = <OnboardingSlideData>[
    OnboardingSlideData(
      title: 'Focus on What Matters.',
      subtitle: 'Build better study habits with focused study sessions.',
    ),
    OnboardingSlideData(
      title: 'Plan Your Study Routine.',
      subtitle: 'Organize your subjects, tasks, and weekly targets in one place.',
    ),
    OnboardingSlideData(
      title: 'See Your Progress Grow.',
      subtitle: 'Track study time, daily goals, streaks, and milestones offline.',
    ),
  ];

  bool get isLastSlide => currentIndex.value == slides.length - 1;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  Future<void> onNextOrGetStarted() async {
    if (!isLastSlide) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await completeOnboarding();
  }

  Future<void> completeOnboarding() async {
    if (isSubmitting.value) {
      return;
    }
    isSubmitting.value = true;
    try {
      await _settingsRepository.setOnboardingCompleted(completed: true);
      await Get.offAllNamed<void>(AppRoutes.home);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
