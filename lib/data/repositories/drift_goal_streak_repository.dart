import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/domain_entities.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';
import '../models/data_mappers.dart';

class DriftGoalStreakRepository implements GoalStreakRepository {
  DriftGoalStreakRepository(
    this._db, {
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _nowProvider;

  @override
  Future<int> getDailyGoalMinutes({String? dateKey}) async {
    if (dateKey != null) {
      final dateSpecific = await _db.goalStreakDao.getGoalForDate(dateKey);
      if (dateSpecific != null) {
        return dateSpecific.targetMinutes;
      }
    }
    final raw = await _db.settingsDao.getValue(AppDatabase.keyDailyGoalMinutes);
    return int.tryParse(raw ?? '') ?? 240;
  }

  @override
  Future<void> setDailyGoalMinutes(int minutes, {String? dateKey}) async {
    final nowMs = _nowProvider().toUtc().millisecondsSinceEpoch;
    final targetKey = dateKey ?? DateTimeUtils.toDateKey(_nowProvider());
    await _db.transaction(() async {
      await _db.settingsDao.setValue(
        AppDatabase.keyDailyGoalMinutes,
        minutes.toString(),
      );
      await _db.goalStreakDao.upsertDailyGoal(
        dateKey: targetKey,
        targetMinutes: minutes,
        nowMs: nowMs,
      );
    });
  }

  @override
  Future<int> getWeeklyGoalMinutes() async {
    final raw =
        await _db.settingsDao.getValue(AppDatabase.keyWeeklyGoalMinutes);
    return int.tryParse(raw ?? '') ?? 1200;
  }

  @override
  Future<void> setWeeklyGoalMinutes(int minutes) {
    return _db.settingsDao.setValue(
      AppDatabase.keyWeeklyGoalMinutes,
      minutes.toString(),
    );
  }

  @override
  Stream<StreakSummaryEntity> watchStreakSummary() {
    return _db.goalStreakDao
        .watchAllStreakRecords()
        .map((rows) => _buildSummary(rows));
  }

  @override
  Future<StreakSummaryEntity> getStreakSummary() async {
    final rows = await _db.goalStreakDao.getAllStreakRecords();
    return _buildSummary(rows);
  }

  StreakSummaryEntity _buildSummary(List<StreakRecord> rows) {
    final recordsByDate = <String, StreakDayRecordEntity>{
      for (final row in rows) row.dateKey: row.toEntity(),
    };

    final qualifiedKeys = rows
        .where((r) => r.streakQualified)
        .map((r) => r.dateKey)
        .toList()
      ..sort();

    final longest = _computeLongestStreak(qualifiedKeys);
    final current = _computeCurrentStreak(recordsByDate);

    return StreakSummaryEntity(
      currentStreak: current,
      longestStreak: longest,
      recordsByDate: recordsByDate,
    );
  }

  int _computeLongestStreak(List<String> sortedQualifiedKeys) {
    if (sortedQualifiedKeys.isEmpty) {
      return 0;
    }
    var longest = 0;
    var run = 0;
    DateTime? previous;

    for (final key in sortedQualifiedKeys) {
      final date = DateTimeUtils.parseDateKey(key);
      if (previous != null && date.difference(previous).inDays == 1) {
        run += 1;
      } else {
        run = 1;
      }
      if (run > longest) {
        longest = run;
      }
      previous = date;
    }
    return longest;
  }

  int _computeCurrentStreak(Map<String, StreakDayRecordEntity> map) {
    final today = DateTimeUtils.startOfDay(_nowProvider());
    final todayKey = DateTimeUtils.toDateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = DateTimeUtils.toDateKey(yesterday);

    DateTime cursor;
    if (map[todayKey]?.streakQualified ?? false) {
      cursor = today;
    } else if (map[yesterdayKey]?.streakQualified ?? false) {
      cursor = yesterday;
    } else {
      return 0;
    }

    var count = 0;
    while (true) {
      final key = DateTimeUtils.toDateKey(cursor);
      if (map[key]?.streakQualified ?? false) {
        count += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }
}
