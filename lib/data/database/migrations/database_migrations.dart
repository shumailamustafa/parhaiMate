import 'package:drift/drift.dart';

/// Database migration, index creation, and initial seeding helpers.
abstract final class DatabaseMigrations {
  static const int currentSchemaVersion = 1;

  static Future<void> createIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_subject ON study_sessions(subject_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_started ON study_sessions(started_at);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_status ON study_sessions(status);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_date ON planner_tasks(scheduled_date);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_subject ON planner_tasks(subject_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_streak_date ON streak_records(date_key);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_events_session ON session_events(session_id);',
    );
  }
}
