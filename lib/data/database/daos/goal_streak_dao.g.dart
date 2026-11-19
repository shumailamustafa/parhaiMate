// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_streak_dao.dart';

// ignore_for_file: type=lint
mixin _$GoalStreakDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyGoalsTable get dailyGoals => attachedDatabase.dailyGoals;
  $StreakRecordsTable get streakRecords => attachedDatabase.streakRecords;
  GoalStreakDaoManager get managers => GoalStreakDaoManager(this);
}

class GoalStreakDaoManager {
  final _$GoalStreakDaoMixin _db;
  GoalStreakDaoManager(this._db);
  $$DailyGoalsTableTableManager get dailyGoals =>
      $$DailyGoalsTableTableManager(_db.attachedDatabase, _db.dailyGoals);
  $$StreakRecordsTableTableManager get streakRecords =>
      $$StreakRecordsTableTableManager(_db.attachedDatabase, _db.streakRecords);
}
