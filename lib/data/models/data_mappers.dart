import '../../domain/entities/domain_entities.dart';
import '../../domain/enums/domain_enums.dart';
import '../database/app_database.dart';

extension SubjectRowMapper on Subject {
  SubjectEntity toEntity() {
    return SubjectEntity(
      id: id,
      name: name,
      identifier: SubjectIdentifier.fromKey(color),
      iconKey: SubjectIconKey.fromKey(icon),
      targetMinutes: targetMinutes,
      createdAtMs: createdAt,
      updatedAtMs: updatedAt,
      isArchived: isArchived,
    );
  }
}

extension StudySessionRowMapper on StudySession {
  StudySessionEntity toEntity() {
    return StudySessionEntity(
      id: id,
      subjectId: subjectId,
      sessionType: TimerMode.fromKey(sessionType),
      startedAtMs: startedAt,
      endedAtMs: endedAt,
      durationSeconds: durationSeconds,
      status: SessionStatus.fromKey(status),
      notes: notes,
      createdAtMs: createdAt,
    );
  }
}

extension PlannerTaskRowMapper on PlannerTask {
  PlannerTaskEntity toEntity() {
    return PlannerTaskEntity(
      id: id,
      subjectId: subjectId,
      title: title,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      targetMinutes: targetMinutes,
      notes: notes,
      isCompleted: isCompleted,
      createdAtMs: createdAt,
      updatedAtMs: updatedAt,
    );
  }
}

extension TimerPresetRowMapper on TimerPreset {
  TimerPresetEntity toEntity() {
    return TimerPresetEntity(
      id: id,
      name: name,
      timerMode: TimerMode.fromKey(timerMode),
      focusMinutes: focusMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak,
      isDefault: isDefault,
    );
  }
}

extension DailyGoalRowMapper on DailyGoal {
  DailyGoalEntity toEntity() {
    return DailyGoalEntity(
      id: id,
      dateKey: dateKey,
      targetMinutes: targetMinutes,
      createdAtMs: createdAt,
    );
  }
}

extension StreakRecordRowMapper on StreakRecord {
  StreakDayRecordEntity toEntity() {
    return StreakDayRecordEntity(
      dateKey: dateKey,
      studyMinutes: studyMinutes,
      streakQualified: streakQualified,
    );
  }
}

extension ActiveTimerRowMapper on ActiveTimerState {
  ActiveTimerEntity toEntity() {
    return ActiveTimerEntity(
      sessionId: sessionId,
      subjectId: subjectId,
      timerMode: TimerMode.fromKey(timerMode),
      phase: TimerPhase.fromKey(phase),
      targetEndAtMs: targetEndAt,
      segmentStartedAtMs: segmentStartedAt,
      phasePausedRemainingSeconds: phasePausedRemainingSeconds,
      accumulatedSeconds: accumulatedSeconds,
      plannedDurationSeconds: plannedDurationSeconds,
      focusMinutes: focusMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      totalCycles: totalCycles,
      currentCycle: currentCycle,
      isPaused: isPaused,
      notes: notes,
      updatedAtMs: updatedAt,
    );
  }
}
