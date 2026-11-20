import 'package:get/get.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/services/timer_engine_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/drift_repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../../features/backup/services/backup_service.dart';
import '../../features/backup/services/report_service.dart';
import '../lifecycle/app_lifecycle_handler.dart';

/// Registers long-lived core singletons (database, repositories, timer engine).
class InitialBinding extends Bindings {
  InitialBinding({
    AppDatabase? database,
    LocalNotificationService? notificationService,
  })  : _databaseOverride = database,
        _notificationService = notificationService;

  final AppDatabase? _databaseOverride;

  /// Initialized in `main()`. When omitted (tests) an uninitialized
  /// instance is used, which makes every alert call a no-op.
  final LocalNotificationService? _notificationService;

  @override
  void dependencies() {
    final db = _databaseOverride ?? AppDatabase();
    Get.put<AppDatabase>(db, permanent: true);

    final subjectRepo = DriftSubjectRepository(db);
    final goalStreakRepo = DriftGoalStreakRepository(db);
    final achievementRepo = DriftAchievementRepository(db, goalStreakRepo);
    final sessionRepo = DriftSessionRepository(db, achievementRepo);
    final plannerRepo = DriftPlannerRepository(db);
    final presetRepo = DriftPresetRepository(db);
    final settingsRepo = DriftSettingsRepository(db);

    Get.put<SubjectRepository>(subjectRepo, permanent: true);
    Get.put<GoalStreakRepository>(goalStreakRepo, permanent: true);
    Get.put<AchievementRepository>(achievementRepo, permanent: true);
    Get.put<SessionRepository>(sessionRepo, permanent: true);
    Get.put<PlannerRepository>(plannerRepo, permanent: true);
    Get.put<PresetRepository>(presetRepo, permanent: true);
    Get.put<SettingsRepository>(settingsRepo, permanent: true);

    final notifications = _notificationService ?? LocalNotificationService();
    Get.put<LocalNotificationService>(notifications, permanent: true);

    final timerEngine = TimerEngineService(
      sessionRepository: sessionRepo,
      activeTimerDao: db.activeTimerDao,
      notifier: notifications,
    );
    Get.put<TimerEngineService>(timerEngine, permanent: true);

    Get.put<BackupService>(
      BackupService(
        database: db,
        goalStreakRepository: goalStreakRepo,
        settingsRepository: settingsRepo,
        achievementRepository: achievementRepo,
      ),
      permanent: true,
    );
    Get.put<ReportService>(
      ReportService(
        sessionRepository: sessionRepo,
        subjectRepository: subjectRepo,
      ),
      permanent: true,
    );

    final lifecycle = AppLifecycleHandler(timerEngine)..attach();
    Get.put<AppLifecycleHandler>(lifecycle, permanent: true);
  }
}
