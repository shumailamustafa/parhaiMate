import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/timer_engine_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/repositories/repositories.dart';
import '../../features/home/viewmodels/home_viewmodel.dart';
import '../../features/home/viewmodels/main_shell_viewmodel.dart';
import '../../features/home/views/main_shell_view.dart';
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
      name: AppRoutes.home,
      page: () => const MainShellView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<MainShellViewModel>(
          () => MainShellViewModel(
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );
        Get.lazyPut<HomeViewModel>(
          () => HomeViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
            plannerRepository: Get.find<PlannerRepository>(),
            goalStreakRepository: Get.find<GoalStreakRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.components,
      page: () => const ComponentLibraryView(),
    ),
    // Secondary routes referenced from Home Dashboard (implemented in 5.3 - 5.7).
    GetPage<void>(
      name: AppRoutes.sessionSetup,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Set Up Your Session',
        subtitle: 'Session Setup will be implemented in Section 5.3.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.activeFocus,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Active Focus',
        subtitle: 'Active Focus timer view will be implemented in Section 5.3.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.addSubject,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Add Subject',
        subtitle: 'Add & Edit Subject will be implemented in Section 5.4.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.planner,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Study Planner',
        subtitle: 'Study Planner will be implemented in Section 5.5.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.addTask,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Add Study Task',
        subtitle: 'Add & Edit Study Task will be implemented in Section 5.5.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.editTask,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Edit Study Task',
        subtitle: 'Add & Edit Study Task will be implemented in Section 5.5.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.sessionHistory,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Session History',
        subtitle: 'Session History will be implemented in Section 5.6.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.settings,
      page: () => _UpcomingRoutePlaceholder(
        title: 'Settings',
        subtitle: 'Full Settings & Backup will be implemented in Section 5.7.',
        extraActionLabel: 'Open Component Library',
        onExtraAction: () => Get.toNamed<void>(AppRoutes.components),
      ),
    ),
  ];
}

class _UpcomingRoutePlaceholder extends StatelessWidget {
  const _UpcomingRoutePlaceholder({
    required this.title,
    required this.subtitle,
    this.extraActionLabel,
    this.onExtraAction,
  });

  final String title;
  final String subtitle;
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PmAppBar(title: title),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Center(
          child: PmEmptyState(
            icon: Icons.construction_outlined,
            title: title,
            subtitle: subtitle,
            actionLabel: extraActionLabel,
            onAction: onExtraAction,
          ),
        ),
      ),
    );
  }
}
