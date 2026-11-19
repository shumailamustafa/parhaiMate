import 'package:drift/drift.dart';

import 'subjects_table.dart';

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer()
      .named('subject_id')
      .nullable()
      .references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionType => text().named('session_type')();
  IntColumn get startedAt => integer().named('started_at')();
  IntColumn get endedAt => integer().named('ended_at').nullable()();
  IntColumn get durationSeconds =>
      integer().named('duration_seconds').withDefault(const Constant(0))();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
}
