import 'package:drift/drift.dart';

class DailyGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateKey => text().named('date_key').unique()();
  IntColumn get targetMinutes => integer().named('target_minutes')();
  IntColumn get createdAt => integer().named('created_at')();
}
