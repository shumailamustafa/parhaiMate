import 'package:drift/drift.dart';

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get color => text().withDefault(const Constant('circle'))();
  TextColumn get icon => text().withDefault(const Constant('book'))();
  IntColumn get targetMinutes =>
      integer().named('target_minutes').withDefault(const Constant(300))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();
}
