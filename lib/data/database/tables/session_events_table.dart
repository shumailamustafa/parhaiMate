import 'package:drift/drift.dart';

import 'study_sessions_table.dart';

class SessionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()
      .named('session_id')
      .references(StudySessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventType => text().named('event_type')();
  IntColumn get startedAt => integer().named('started_at')();
  IntColumn get endedAt => integer().named('ended_at')();
  IntColumn get durationSeconds => integer().named('duration_seconds')();
}
