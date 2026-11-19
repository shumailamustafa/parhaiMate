import 'package:drift/drift.dart';

import 'study_sessions_table.dart';
import 'subjects_table.dart';

class ActiveTimerStates extends Table {
  IntColumn get id => integer()();
  IntColumn get sessionId => integer()
      .named('session_id')
      .nullable()
      .references(StudySessions, #id, onDelete: KeyAction.setNull)();
  IntColumn get subjectId => integer()
      .named('subject_id')
      .nullable()
      .references(Subjects, #id, onDelete: KeyAction.setNull)();
  TextColumn get timerMode => text().named('timer_mode')();
  TextColumn get phase => text()();
  IntColumn get targetEndAt => integer().named('target_end_at').nullable()();
  IntColumn get segmentStartedAt =>
      integer().named('segment_started_at').nullable()();
  IntColumn get phasePausedRemainingSeconds =>
      integer().named('phase_paused_remaining_seconds').nullable()();
  IntColumn get accumulatedSeconds =>
      integer().named('accumulated_seconds').withDefault(const Constant(0))();
  IntColumn get plannedDurationSeconds => integer()
      .named('planned_duration_seconds')
      .withDefault(const Constant(0))();
  IntColumn get focusMinutes =>
      integer().named('focus_minutes').withDefault(const Constant(25))();
  IntColumn get shortBreakMinutes =>
      integer().named('short_break_minutes').withDefault(const Constant(5))();
  IntColumn get longBreakMinutes =>
      integer().named('long_break_minutes').withDefault(const Constant(15))();
  IntColumn get totalCycles =>
      integer().named('total_cycles').withDefault(const Constant(4))();
  IntColumn get currentCycle =>
      integer().named('current_cycle').withDefault(const Constant(1))();
  BoolColumn get isPaused =>
      boolean().named('is_paused').withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
