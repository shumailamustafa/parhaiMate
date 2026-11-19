import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/domain_entities.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';

class DriftAchievementRepository implements AchievementRepository {
  DriftAchievementRepository(
    this._db,
    this._goalStreakRepository, {
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final AppDatabase _db;
  final GoalStreakRepository _goalStreakRepository;
  final DateTime Function() _nowProvider;

  @override
  Stream<List<AchievementEntity>> watchAchievements() {
    return _db.achievementDao
        .watchAllAchievements()
        .asyncMap((rows) => _hydrate(rows));
  }

  @override
  Future<List<AchievementEntity>> getAchievements() async {
    final rows = await _db.achievementDao.getAllAchievements();
    return _hydrate(rows);
  }

  @override
  Future<void> evaluateAndUnlock({required int nowMs}) async {
    final sessions = await _db.sessionDao.getCompletedSessions();
    final totalSessions = sessions.length;
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    final streak = await _goalStreakRepository.getStreakSummary();
    final weeklyMinutes = await _currentWeekMinutes(sessions);
    final weeklyGoalMinutes =
        await _goalStreakRepository.getWeeklyGoalMinutes();

    if (totalSessions >= 1) {
      await _db.achievementDao.unlockAchievement('first_session', nowMs);
    }
    if (totalSeconds >= 3600) {
      await _db.achievementDao.unlockAchievement('focus_starter', nowMs);
    }
    if (streak.longestStreak >= 7) {
      await _db.achievementDao.unlockAchievement('consistent_learner', nowMs);
    }
    if (totalSessions >= 25) {
      await _db.achievementDao.unlockAchievement('study_champion', nowMs);
    }
    if (totalSeconds >= 180000) {
      await _db.achievementDao.unlockAchievement('time_master', nowMs);
    }
    if (weeklyGoalMinutes > 0 && weeklyMinutes >= weeklyGoalMinutes) {
      await _db.achievementDao.unlockAchievement('weekly_warrior', nowMs);
    }
  }

  Future<int> _currentWeekMinutes(List<StudySession> sessions) async {
    final now = _nowProvider();
    final weekStart = DateTimeUtils.startOfWeek(now).toUtc().millisecondsSinceEpoch;
    final weekEnd =
        DateTimeUtils.endOfWeekExclusive(now).toUtc().millisecondsSinceEpoch;
    var totalSeconds = 0;
    for (final s in sessions) {
      if (s.startedAt >= weekStart && s.startedAt < weekEnd) {
        totalSeconds += s.durationSeconds;
      }
    }
    return totalSeconds ~/ 60;
  }

  Future<List<AchievementEntity>> _hydrate(List<Achievement> rows) async {
    final sessions = await _db.sessionDao.getCompletedSessions();
    final totalSessions = sessions.length;
    final totalHours = sessions.fold<int>(
          0,
          (sum, item) => sum + item.durationSeconds,
        ) ~/
        3600;
    final totalMinutes = sessions.fold<int>(
          0,
          (sum, item) => sum + item.durationSeconds,
        ) ~/
        60;
    final streak = await _goalStreakRepository.getStreakSummary();
    final weeklyMinutes = await _currentWeekMinutes(sessions);
    final weeklyGoalMinutes =
        await _goalStreakRepository.getWeeklyGoalMinutes();

    final unlockedByCode = <String, int?>{
      for (final r in rows) r.achievementCode: r.unlockedAt,
    };

    return <AchievementEntity>[
      AchievementEntity(
        code: 'first_session',
        title: 'First Session',
        description: 'Complete your first study session.',
        targetValue: 1,
        currentValue: totalSessions.clamp(0, 1),
        unitLabel: 'session',
        unlockedAtMs: unlockedByCode['first_session'],
      ),
      AchievementEntity(
        code: 'focus_starter',
        title: 'Focus Starter',
        description: 'Study for 1 hour.',
        targetValue: 60,
        currentValue: totalMinutes.clamp(0, 60),
        unitLabel: 'min',
        unlockedAtMs: unlockedByCode['focus_starter'],
      ),
      AchievementEntity(
        code: 'consistent_learner',
        title: 'Consistent Learner',
        description: 'Study for 7 consecutive days.',
        targetValue: 7,
        currentValue: streak.longestStreak.clamp(0, 7),
        unitLabel: 'days',
        unlockedAtMs: unlockedByCode['consistent_learner'],
      ),
      AchievementEntity(
        code: 'study_champion',
        title: 'Study Champion',
        description: 'Complete 25 sessions.',
        targetValue: 25,
        currentValue: totalSessions.clamp(0, 25),
        unitLabel: 'sessions',
        unlockedAtMs: unlockedByCode['study_champion'],
      ),
      AchievementEntity(
        code: 'time_master',
        title: 'Time Master',
        description: 'Complete 50 hours of study.',
        targetValue: 50,
        currentValue: totalHours.clamp(0, 50),
        unitLabel: 'hours',
        unlockedAtMs: unlockedByCode['time_master'],
      ),
      AchievementEntity(
        code: 'weekly_warrior',
        title: 'Weekly Warrior',
        description: 'Reach your weekly goal.',
        targetValue: weeklyGoalMinutes > 0 ? weeklyGoalMinutes : 1200,
        currentValue: weeklyMinutes.clamp(
          0,
          weeklyGoalMinutes > 0 ? weeklyGoalMinutes : 1200,
        ),
        unitLabel: 'min',
        unlockedAtMs: unlockedByCode['weekly_warrior'],
      ),
    ];
  }
}
