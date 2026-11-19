import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/timer_engine_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/repositories/repositories.dart';
import '../../features/calendar/viewmodels/calendar_viewmodel.dart';
import '../../features/calendar/views/calendar_view.dart';
import '../../features/home/viewmodels/home_viewmodel.dart';
import '../../features/home/viewmodels/main_shell_viewmodel.dart';
import '../../features/home/views/main_shell_view.dart';
import '../../features/onboarding/viewmodels/onboarding_viewmodel.dart';
import '../../features/onboarding/viewmodels/splash_viewmodel.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/onboarding/views/splash_view.dart';
import '../../features/planner/viewmodels/planner_viewmodel.dart';
import '../../features/planner/viewmodels/task_form_viewmodel.dart';
import '../../features/planner/views/add_edit_task_view.dart';
import '../../features/planner/views/study_planner_view.dart';
import '../../features/settings/views/component_library_view.dart';
import '../../features/subjects/viewmodels/subject_details_viewmodel.dart';
import '../../features/subjects/viewmodels/subject_form_viewmodel.dart';
import '../../features/subjects/viewmodels/subjects_viewmodel.dart';
import '../../features/subjects/views/add_edit_subject_view.dart';
import '../../features/subjects/views/subject_details_view.dart';
import '../../features/subjects/views/subjects_view.dart';
import '../../features/timer/viewmodels/active_focus_viewmodel.dart';
import '../../features/timer/viewmodels/session_setup_viewmodel.dart';
import '../../features/timer/viewmodels/session_summary_viewmodel.dart';
import '../../features/timer/viewmodels/study_timer_viewmodel.dart';
import '../../features/timer/views/active_focus_view.dart';
import '../../features/timer/views/session_setup_view.dart';
import '../../features/timer/views/session_summary_view.dart';
import '../../features/timer/views/study_timer_view.dart';
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
        Get.lazyPut<StudyTimerViewModel>(
          () => StudyTimerViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            settingsRepository: Get.find<SettingsRepository>(),
          ),
        );
        Get.lazyPut<SubjectsViewModel>(
          () => SubjectsViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.subjects,
      page: () => const Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(title: 'My Subjects'),
        body: SubjectsView(showTitleHeader: false),
      ),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SubjectsViewModel>(
          () => SubjectsViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.subjectDetails,
      page: () => const SubjectDetailsView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SubjectDetailsViewModel>(
          () => SubjectDetailsViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
            plannerRepository: Get.find<PlannerRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.editSubject,
      page: () => const AddEditSubjectView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SubjectFormViewModel>(
          () => SubjectFormViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
            plannerRepository: Get.find<PlannerRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.timer,
      page: () => const Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(title: 'Study Timer'),
        body: StudyTimerView(showTitleHeader: false),
      ),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<StudyTimerViewModel>(
          () => StudyTimerViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            settingsRepository: Get.find<SettingsRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.components,
      page: () => const ComponentLibraryView(),
    ),
    GetPage<void>(
      name: AppRoutes.sessionSetup,
      page: () => const SessionSetupView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SessionSetupViewModel>(
          () => SessionSetupViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            settingsRepository: Get.find<SettingsRepository>(),
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.activeFocus,
      page: () => const ActiveFocusView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<ActiveFocusViewModel>(
          () => ActiveFocusViewModel(
            timerEngine: Get.find<TimerEngineService>(),
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.sessionSummary,
      page: () => const SessionSummaryView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SessionSummaryViewModel>(
          () => SessionSummaryViewModel(
            sessionRepository: Get.find<SessionRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.timerPresets,
      page: () => const _UpcomingRoutePlaceholder(
        title: 'Timer Presets',
        subtitle: 'Timer Preset Management will be implemented in Section 5.7.',
      ),
    ),
    GetPage<void>(
      name: AppRoutes.addSubject,
      page: () => const AddEditSubjectView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SubjectFormViewModel>(
          () => SubjectFormViewModel(
            subjectRepository: Get.find<SubjectRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
            plannerRepository: Get.find<PlannerRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.planner,
      page: () => const StudyPlannerView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<PlannerViewModel>(
          () => PlannerViewModel(
            plannerRepository: Get.find<PlannerRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.addTask,
      page: () => const AddEditTaskView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<TaskFormViewModel>(
          () => TaskFormViewModel(
            plannerRepository: Get.find<PlannerRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.editTask,
      page: () => const AddEditTaskView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<TaskFormViewModel>(
          () => TaskFormViewModel(
            plannerRepository: Get.find<PlannerRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.calendar,
      page: () => const CalendarView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<CalendarViewModel>(
          () => CalendarViewModel(
            sessionRepository: Get.find<SessionRepository>(),
            plannerRepository: Get.find<PlannerRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
          ),
        );
      }),
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
