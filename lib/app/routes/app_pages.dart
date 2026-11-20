import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/services/timer_engine_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/repositories/repositories.dart';
import '../../features/achievements/viewmodels/achievements_viewmodel.dart';
import '../../features/achievements/views/achievements_view.dart';
import '../../features/backup/services/backup_service.dart';
import '../../features/backup/services/report_service.dart';
import '../../features/backup/viewmodels/backup_viewmodel.dart';
import '../../features/backup/viewmodels/export_report_viewmodel.dart';
import '../../features/backup/views/export_backup_view.dart';
import '../../features/backup/views/export_report_view.dart';
import '../../features/backup/views/import_backup_view.dart';
import '../../features/calendar/viewmodels/calendar_viewmodel.dart';
import '../../features/calendar/views/calendar_view.dart';
import '../../features/goals/viewmodels/goals_viewmodel.dart';
import '../../features/goals/views/goals_streaks_view.dart';
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
import '../../features/settings/viewmodels/goal_config_viewmodel.dart';
import '../../features/settings/viewmodels/presets_viewmodel.dart';
import '../../features/settings/viewmodels/settings_viewmodel.dart';
import '../../features/settings/views/component_library_view.dart';
import '../../features/settings/views/goal_config_views.dart';
import '../../features/settings/views/navigation_flow_view.dart';
import '../../features/settings/views/presets_views.dart';
import '../../features/settings/views/privacy_policy_view.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/statistics/viewmodels/session_history_viewmodel.dart';
import '../../features/statistics/viewmodels/statistics_viewmodel.dart';
import '../../features/statistics/views/session_history_view.dart';
import '../../features/statistics/views/statistics_view.dart';
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
            notificationService:
                Get.isRegistered<LocalNotificationService>()
                    ? Get.find<LocalNotificationService>()
                    : null,
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
        Get.lazyPut<StatisticsViewModel>(
          () => StatisticsViewModel(
            sessionRepository: Get.find<SessionRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            achievementRepository: Get.find<AchievementRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.progress,
      page: () => const Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(title: 'Statistics'),
        body: StatisticsView(showTitleHeader: false),
      ),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<StatisticsViewModel>(
          () => StatisticsViewModel(
            sessionRepository: Get.find<SessionRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            achievementRepository: Get.find<AchievementRepository>(),
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
    // Developer-only screens are not registered in release builds.
    if (kDebugMode)
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
            notificationService:
                Get.isRegistered<LocalNotificationService>()
                    ? Get.find<LocalNotificationService>()
                    : null,
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
      page: () => const PresetsListView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<PresetsViewModel>(
          () => PresetsViewModel(
            presetRepository: Get.find<PresetRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.createPreset,
      page: () => const PresetFormView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<PresetFormViewModel>(
          () => PresetFormViewModel(
            presetRepository: Get.find<PresetRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.editPreset,
      page: () => const PresetFormView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<PresetFormViewModel>(
          () => PresetFormViewModel(
            presetRepository: Get.find<PresetRepository>(),
          ),
        );
      }),
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
      page: () => const SessionHistoryView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SessionHistoryViewModel>(
          () => SessionHistoryViewModel(
            sessionRepository: Get.find<SessionRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.goals,
      page: () => const GoalsStreaksView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<GoalsViewModel>(
          () => GoalsViewModel(
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.achievements,
      page: () => const AchievementsView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<AchievementsViewModel>(
          () => AchievementsViewModel(
            achievementRepository: Get.find<AchievementRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<SettingsViewModel>(
          () => SettingsViewModel(
            settingsRepository: Get.find<SettingsRepository>(),
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            presetRepository: Get.find<PresetRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
            subjectRepository: Get.find<SubjectRepository>(),
            timerEngine: Get.find<TimerEngineService>(),
            notificationService:
                Get.isRegistered<LocalNotificationService>()
                    ? Get.find<LocalNotificationService>()
                    : null,
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.dailyGoalConfig,
      page: () => const DailyGoalConfigView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<GoalConfigViewModel>(
          () => GoalConfigViewModel(
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.weeklyGoalConfig,
      page: () => const WeeklyGoalConfigView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<GoalConfigViewModel>(
          () => GoalConfigViewModel(
            goalStreakRepository: Get.find<GoalStreakRepository>(),
            sessionRepository: Get.find<SessionRepository>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.exportBackup,
      page: () => const ExportBackupView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<BackupViewModel>(
          () => BackupViewModel(
            backupService: Get.find<BackupService>(),
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.importBackup,
      page: () => const ImportBackupView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<BackupViewModel>(
          () => BackupViewModel(
            backupService: Get.find<BackupService>(),
            timerEngine: Get.find<TimerEngineService>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.studyReport,
      page: () => const ExportReportView(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut<ExportReportViewModel>(
          () => ExportReportViewModel(
            reportService: Get.find<ReportService>(),
          ),
        );
      }),
    ),
    GetPage<void>(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyView(),
    ),
    if (kDebugMode)
      GetPage<void>(
        name: AppRoutes.navigationFlow,
        page: () => const NavigationFlowView(),
      ),
  ];
}
