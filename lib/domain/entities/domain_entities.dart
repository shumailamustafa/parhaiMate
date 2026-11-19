import '../enums/domain_enums.dart';

class SubjectEntity {
  const SubjectEntity({
    required this.id,
    required this.name,
    required this.identifier,
    required this.iconKey,
    required this.targetMinutes,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.isArchived,
  });

  final int id;
  final String name;
  final SubjectIdentifier identifier;
  final SubjectIconKey iconKey;
  final int targetMinutes;
  final int createdAtMs;
  final int updatedAtMs;
  final bool isArchived;
}

class StudySessionEntity {
  const StudySessionEntity({
    required this.id,
    required this.subjectId,
    required this.sessionType,
    required this.startedAtMs,
    required this.endedAtMs,
    required this.durationSeconds,
    required this.status,
    required this.notes,
    required this.createdAtMs,
  });

  final int id;
  final int? subjectId;
  final TimerMode sessionType;
  final int startedAtMs;
  final int? endedAtMs;
  final int durationSeconds;
  final SessionStatus status;
  final String? notes;
  final int createdAtMs;
}

class PlannerTaskEntity {
  const PlannerTaskEntity({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.targetMinutes,
    required this.notes,
    required this.isCompleted,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final int id;
  final int? subjectId;
  final String title;
  final String scheduledDate;
  final String? scheduledTime;
  final int targetMinutes;
  final String? notes;
  final bool isCompleted;
  final int createdAtMs;
  final int updatedAtMs;
}

class TimerPresetEntity {
  const TimerPresetEntity({
    required this.id,
    required this.name,
    required this.timerMode,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.cyclesBeforeLongBreak,
    required this.isDefault,
  });

  final int id;
  final String name;
  final TimerMode timerMode;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int cyclesBeforeLongBreak;
  final bool isDefault;

  int get totalSessionMinutes {
    switch (timerMode) {
      case TimerMode.focus:
        return focusMinutes;
      case TimerMode.stopwatch:
        return 0;
      case TimerMode.pomodoro:
        final breaks = cyclesBeforeLongBreak > 1
            ? (cyclesBeforeLongBreak - 1) * shortBreakMinutes
            : 0;
        return (cyclesBeforeLongBreak * focusMinutes) + breaks;
    }
  }
}

class DailyGoalEntity {
  const DailyGoalEntity({
    required this.id,
    required this.dateKey,
    required this.targetMinutes,
    required this.createdAtMs,
  });

  final int id;
  final String dateKey;
  final int targetMinutes;
  final int createdAtMs;
}

class StreakDayRecordEntity {
  const StreakDayRecordEntity({
    required this.dateKey,
    required this.studyMinutes,
    required this.streakQualified,
  });

  final String dateKey;
  final int studyMinutes;
  final bool streakQualified;
}

class StreakSummaryEntity {
  const StreakSummaryEntity({
    required this.currentStreak,
    required this.longestStreak,
    required this.recordsByDate,
  });

  final int currentStreak;
  final int longestStreak;
  final Map<String, StreakDayRecordEntity> recordsByDate;
}

class AchievementEntity {
  const AchievementEntity({
    required this.code,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unitLabel,
    required this.unlockedAtMs,
  });

  final String code;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final String unitLabel;
  final int? unlockedAtMs;

  bool get isUnlocked => unlockedAtMs != null;

  double get progress =>
      targetValue <= 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);
}

class ActiveTimerEntity {
  const ActiveTimerEntity({
    required this.sessionId,
    required this.subjectId,
    required this.timerMode,
    required this.phase,
    required this.targetEndAtMs,
    required this.segmentStartedAtMs,
    required this.phasePausedRemainingSeconds,
    required this.accumulatedSeconds,
    required this.plannedDurationSeconds,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalCycles,
    required this.currentCycle,
    required this.isPaused,
    required this.notes,
    required this.updatedAtMs,
  });

  final int? sessionId;
  final int? subjectId;
  final TimerMode timerMode;
  final TimerPhase phase;
  final int? targetEndAtMs;
  final int? segmentStartedAtMs;
  final int? phasePausedRemainingSeconds;
  final int accumulatedSeconds;
  final int plannedDurationSeconds;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int totalCycles;
  final int currentCycle;
  final bool isPaused;
  final String? notes;
  final int updatedAtMs;
}
