import 'package:get/get.dart';

import '../../core/services/timer_engine_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/drift_repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../lifecycle/app_lifecycle_handler.dart';

/// Registers long-lived core singletons (database, repositories, timer engine).
class InitialBinding extends Bindings {
  InitialBinding({AppDatabase? database}) : _databaseOverride = database;

  final AppDatabase? _databaseOverride;

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

    final timerEngine = TimerEngineService(
      sessionRepository: sessionRepo,
      activeTimerDao: db.activeTimerDao,
    );
    Get.put<TimerEngineService>(timerEngine, permanent: true);

    final lifecycle = AppLifecycleHandler(timerEngine)..attach();
    Get.put<AppLifecycleHandler>(lifecycle, permanent: true);
  }
}
