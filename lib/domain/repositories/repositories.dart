import '../entities/domain_entities.dart';
import '../enums/domain_enums.dart';

abstract interface class SubjectRepository {
  Stream<List<SubjectEntity>> watchSubjects({bool? archived});
  Future<List<SubjectEntity>> getSubjects({bool? archived});
  Future<SubjectEntity?> getById(int id);
  Stream<SubjectEntity?> watchById(int id);
  Future<int> createSubject({
    required String name,
    required SubjectIdentifier identifier,
    required SubjectIconKey iconKey,
    required int targetMinutes,
  });
  Future<void> updateSubject(SubjectEntity subject);
  Future<void> setArchived(int id, {required bool isArchived});
  Future<void> deleteSubject(int id);
}

abstract interface class SessionRepository {
  Stream<List<StudySessionEntity>> watchCompletedSessions({int? subjectId});
  Future<List<StudySessionEntity>> getCompletedSessions({
    int? subjectId,
    int? startMsInclusive,
    int? endMsExclusive,
  });
  Future<StudySessionEntity?> getById(int id);
  Future<int> createActiveSession({
    required int? subjectId,
    required TimerMode mode,
    required int startedAtMs,
    String? notes,
  });
  Future<void> recordSessionEvent({
    required int sessionId,
    required String eventType,
    required int startedAtMs,
    required int endedAtMs,
    required int durationSeconds,
  });
  Future<StudySessionEntity> completeSession({
    required int sessionId,
    required int endedAtMs,
    required int durationSeconds,
    String? notes,
  });
  Future<void> cancelSession({
    required int sessionId,
    required int cancelledAtMs,
  });
  Future<void> updateSessionNotes(int sessionId, String? notes);
  Future<void> clearHistory();
}

abstract interface class PlannerRepository {
  Stream<List<PlannerTaskEntity>> watchTasksForDate(String dateKey);
  Stream<List<PlannerTaskEntity>> watchAllTasks();
  Future<List<PlannerTaskEntity>> getTasksForDate(String dateKey);
  Future<List<PlannerTaskEntity>> getAllTasks();
  Future<PlannerTaskEntity?> getById(int id);
  Future<int> createTask({
    required int? subjectId,
    required String title,
    required String scheduledDate,
    String? scheduledTime,
    required int targetMinutes,
    String? notes,
  });
  Future<void> updateTask(PlannerTaskEntity task);
  Future<void> toggleTaskCompletion(int id, {required bool isCompleted});
  Future<void> deleteTask(int id);
}

abstract interface class GoalStreakRepository {
  Future<int> getDailyGoalMinutes({String? dateKey});
  Future<void> setDailyGoalMinutes(int minutes, {String? dateKey});
  Future<int> getWeeklyGoalMinutes();
  Future<void> setWeeklyGoalMinutes(int minutes);
  Stream<StreakSummaryEntity> watchStreakSummary();
  Future<StreakSummaryEntity> getStreakSummary();
}

abstract interface class PresetRepository {
  Stream<List<TimerPresetEntity>> watchPresets();
  Future<List<TimerPresetEntity>> getPresets();
  Future<TimerPresetEntity?> getById(int id);
  Future<int> createPreset({
    required String name,
    required TimerMode timerMode,
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int cyclesBeforeLongBreak,
  });
  Future<void> updatePreset(TimerPresetEntity preset);
  Future<void> deletePreset(int id);
}

abstract interface class AchievementRepository {
  Stream<List<AchievementEntity>> watchAchievements();
  Future<List<AchievementEntity>> getAchievements();
  Future<void> evaluateAndUnlock({required int nowMs});
}

abstract interface class SettingsRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted({required bool completed});
  Future<TimerMode> getDefaultTimerMode();
  Future<void> setDefaultTimerMode(TimerMode mode);
  Future<void> resetAllAppData();
}
