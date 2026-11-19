import 'package:drift/drift.dart';

class StreakRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateKey => text().named('date_key').unique()();
  IntColumn get studyMinutes =>
      integer().named('study_minutes').withDefault(const Constant(0))();
  BoolColumn get streakQualified =>
      boolean().named('streak_qualified').withDefault(const Constant(false))();
}
