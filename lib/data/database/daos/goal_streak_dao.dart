import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/daily_goals_table.dart';
import '../tables/streak_records_table.dart';

part 'goal_streak_dao.g.dart';

@DriftAccessor(tables: <Type>[DailyGoals, StreakRecords])
class GoalStreakDao extends DatabaseAccessor<AppDatabase>
    with _$GoalStreakDaoMixin {
  GoalStreakDao(super.db);

  Future<DailyGoal?> getGoalForDate(String dateKey) {
    return (select(dailyGoals)..where((t) => t.dateKey.equals(dateKey)))
        .getSingleOrNull();
  }

  Future<List<DailyGoal>> getAllDailyGoals() {
    return (select(dailyGoals)
          ..orderBy(<OrderingTerm Function(DailyGoals)>[
            (t) => OrderingTerm.desc(t.dateKey),
          ]))
        .get();
  }

  Future<int> upsertDailyGoal({
    required String dateKey,
    required int targetMinutes,
    required int nowMs,
  }) {
    return into(dailyGoals).insertOnConflictUpdate(
      DailyGoalsCompanion.insert(
        dateKey: dateKey,
        targetMinutes: targetMinutes,
        createdAt: nowMs,
      ),
    );
  }

  Future<StreakRecord?> getStreakRecordForDate(String dateKey) {
    return (select(streakRecords)..where((t) => t.dateKey.equals(dateKey)))
        .getSingleOrNull();
  }

  Future<List<StreakRecord>> getAllStreakRecords() {
    return (select(streakRecords)
          ..orderBy(<OrderingTerm Function(StreakRecords)>[
            (t) => OrderingTerm.asc(t.dateKey),
          ]))
        .get();
  }

  Stream<List<StreakRecord>> watchAllStreakRecords() {
    return (select(streakRecords)
          ..orderBy(<OrderingTerm Function(StreakRecords)>[
            (t) => OrderingTerm.asc(t.dateKey),
          ]))
        .watch();
  }

  Future<void> addStudyMinutesForDate({
    required String dateKey,
    required int addedMinutes,
  }) async {
    final existing = await getStreakRecordForDate(dateKey);
    final updatedMinutes = (existing?.studyMinutes ?? 0) + addedMinutes;
    final qualified = updatedMinutes > 0;
    if (existing == null) {
      await into(streakRecords).insert(
        StreakRecordsCompanion.insert(
          dateKey: dateKey,
          studyMinutes: Value<int>(updatedMinutes),
          streakQualified: Value<bool>(qualified),
        ),
      );
    } else {
      await (update(streakRecords)..where((t) => t.id.equals(existing.id)))
          .write(
        StreakRecordsCompanion(
          studyMinutes: Value<int>(updatedMinutes),
          streakQualified: Value<bool>(qualified),
        ),
      );
    }
  }

  Future<void> upsertStreakRecord(StreakRecordsCompanion entry) {
    return into(streakRecords).insertOnConflictUpdate(entry);
  }

  Future<int> clearStreakRecords() {
    return delete(streakRecords).go();
  }
}
