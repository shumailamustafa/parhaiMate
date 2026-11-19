import 'package:drift/drift.dart';

import 'subjects_table.dart';

class PlannerTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer()
      .named('subject_id')
      .nullable()
      .references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get scheduledDate => text().named('scheduled_date')();
  TextColumn get scheduledTime => text().named('scheduled_time').nullable()();
  IntColumn get targetMinutes =>
      integer().named('target_minutes').withDefault(const Constant(30))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().named('is_completed').withDefault(const Constant(false))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
}
