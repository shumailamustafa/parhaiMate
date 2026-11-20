import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

class StatBarBucket {
  const StatBarBucket({
    required this.label,
    required this.minutes,
    this.isHighlighted = true,
  });

  final String label;
  final int minutes;
  final bool isHighlighted;
}

class SubjectSliceData {
  const SubjectSliceData({
    required this.subjectId,
    required this.name,
    required this.iconKey,
    required this.minutes,
    required this.percentage,
    required this.paletteIndex,
  });

  final int? subjectId;
  final String name;
  final SubjectIconKey iconKey;
  final int minutes;
  final int percentage;
  final int paletteIndex;
}

class DailyActivityPoint {
  const DailyActivityPoint({
    required this.date,
    required this.minutes,
  });

  final DateTime date;
  final int minutes;
}

/// ViewModel for Progress -> Statistics dashboard (12 Statistics.png & variants).
class StatisticsViewModel extends GetxController {
  StatisticsViewModel({
    required SessionRepository sessionRepository,
    required SubjectRepository subjectRepository,
    required GoalStreakRepository goalStreakRepository,
    required AchievementRepository achievementRepository,
    DateTime Function()? nowProvider,
  })  : _sessionRepository = sessionRepository,
        _subjectRepository = subjectRepository,
        _goalStreakRepository = goalStreakRepository,
        _achievementRepository = achievementRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final SessionRepository _sessionRepository;
  final SubjectRepository _subjectRepository;
  final GoalStreakRepository _goalStreakRepository;
  final AchievementRepository _achievementRepository;
  final DateTime Function() _nowProvider;

  final Rx<StatsPeriod> selectedPeriod = StatsPeriod.week.obs;
  final RxList<StudySessionEntity> allSessions = <StudySessionEntity>[].obs;
  final RxList<SubjectEntity> allSubjects = <SubjectEntity>[].obs;
  final Rxn<StreakSummaryEntity> streakSummary = Rxn<StreakSummaryEntity>();
  final RxList<AchievementEntity> achievements = <AchievementEntity>[].obs;
  final RxInt dailyGoalMinutes = 240.obs;
  final RxInt weeklyGoalMinutes = 1200.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  StreamSubscription<StreakSummaryEntity>? _streakSub;
  StreamSubscription<List<AchievementEntity>>? _achievementsSub;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _sessionsSub = _sessionRepository.watchCompletedSessions().listen((data) {
      allSessions.assignAll(data);
      isLoading.value = false;
      unawaited(refreshGoalTargets());
    });
    _subjectsSub = _subjectRepository.watchSubjects().listen(allSubjects.assignAll);
    _streakSub = _goalStreakRepository
        .watchStreakSummary()
        .listen((value) => streakSummary.value = value);
    _achievementsSub =
        _achievementRepository.watchAchievements().listen(achievements.assignAll);
    unawaited(refreshGoalTargets());
  }

  Future<void> refreshGoalTargets() async {
    final daily = await _goalStreakRepository.getDailyGoalMinutes();
    final weekly = await _goalStreakRepository.getWeeklyGoalMinutes();
    if (!_disposed) {
      dailyGoalMinutes.value = daily;
      weeklyGoalMinutes.value = weekly;
    }
  }

  void setPeriod(StatsPeriod period) {
    selectedPeriod.value = period;
  }

  DateTime get now => _nowProvider();

  String get periodMetaLabel {
    switch (selectedPeriod.value) {
      case StatsPeriod.week:
        return 'This week';
      case StatsPeriod.month:
        return '${DateFormat('MMM').format(now)} to date';
      case StatsPeriod.year:
        return '${now.year}';
    }
  }

  /// Current period plus the matching span of the previous one, so "this
  /// month so far" is compared with the same number of days last month,
  /// not with the whole of last month.
  (int startMs, int endMs, int prevStartMs, int prevEndMs) _periodBounds() {
    final (startMs, endMs, prevStartMs, prevFullEndMs) = _fullPeriodBounds();
    final elapsedMs = now.toUtc().millisecondsSinceEpoch - startMs;
    final prevToDateEndMs =
        math.min<int>(prevStartMs + math.max<int>(0, elapsedMs), prevFullEndMs);
    return (startMs, endMs, prevStartMs, prevToDateEndMs);
  }

  (int startMs, int endMs, int prevStartMs, int prevEndMs) _fullPeriodBounds() {
    final current = now;
    switch (selectedPeriod.value) {
      case StatsPeriod.week:
        final start = DateTimeUtils.startOfWeek(current);
        final end = start.add(const Duration(days: 7));
        final prevStart = start.subtract(const Duration(days: 7));
        return (
          start.toUtc().millisecondsSinceEpoch,
          end.toUtc().millisecondsSinceEpoch,
          prevStart.toUtc().millisecondsSinceEpoch,
          start.toUtc().millisecondsSinceEpoch,
        );
      case StatsPeriod.month:
        final start = DateTime(current.year, current.month, 1);
        final end = DateTime(current.year, current.month + 1, 1);
        final prevStart = DateTime(current.year, current.month - 1, 1);
        return (
          start.toUtc().millisecondsSinceEpoch,
          end.toUtc().millisecondsSinceEpoch,
          prevStart.toUtc().millisecondsSinceEpoch,
          start.toUtc().millisecondsSinceEpoch,
        );
      case StatsPeriod.year:
        final start = DateTime(current.year, 1, 1);
        final end = DateTime(current.year + 1, 1, 1);
        final prevStart = DateTime(current.year - 1, 1, 1);
        return (
          start.toUtc().millisecondsSinceEpoch,
          end.toUtc().millisecondsSinceEpoch,
          prevStart.toUtc().millisecondsSinceEpoch,
          start.toUtc().millisecondsSinceEpoch,
        );
    }
  }

  List<StudySessionEntity> get periodSessions {
    final (startMs, endMs, _, _) = _periodBounds();
    return allSessions
        .where((s) => s.startedAtMs >= startMs && s.startedAtMs < endMs)
        .toList();
  }

  List<StudySessionEntity> get previousPeriodSessions {
    final (_, _, prevStartMs, prevEndMs) = _periodBounds();
    return allSessions
        .where((s) => s.startedAtMs >= prevStartMs && s.startedAtMs < prevEndMs)
        .toList();
  }

  int get totalMinutes =>
      periodSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

  int get previousPeriodMinutes =>
      previousPeriodSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/
      60;

  bool get isComparisonGain => totalMinutes >= previousPeriodMinutes;

  String get comparisonLabel {
    final diff = (totalMinutes - previousPeriodMinutes).abs();
    final noun = switch (selectedPeriod.value) {
      StatsPeriod.week => 'this time last week',
      StatsPeriod.month => 'this time last month',
      StatsPeriod.year => 'this time last year',
    };
    final verb = isComparisonGain ? 'more' : 'less';
    return '${DateTimeUtils.formatMinutes(diff)} $verb than $noun';
  }

  int get sessionsCount => periodSessions.length;

  int get studiedDaysCount {
    final keys = <String>{
      for (final s in periodSessions)
        DateTimeUtils.toDateKey(
          DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
        ),
    };
    return keys.length;
  }

  int get averageDailyMinutes {
    if (periodSessions.isEmpty) {
      return 0;
    }
    final activeDays = studiedDaysCount;
    return activeDays <= 0 ? 0 : (totalMinutes / activeDays).round();
  }

  int get longestSessionMinutes {
    var maxSec = 0;
    for (final s in periodSessions) {
      if (s.durationSeconds > maxSec) {
        maxSec = s.durationSeconds;
      }
    }
    return maxSec ~/ 60;
  }

  int get averageSessionMinutes {
    if (periodSessions.isEmpty) {
      return 0;
    }
    final totalSec =
        periodSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return (totalSec / periodSessions.length / 60).round();
  }

  String get barChartTitle {
    switch (selectedPeriod.value) {
      case StatsPeriod.week:
        return 'Weekly Study Time';
      case StatsPeriod.month:
        return 'Monthly Study Time';
      case StatsPeriod.year:
        return 'Yearly Study Time';
    }
  }

  List<StatBarBucket> get barBuckets {
    final sessions = periodSessions;
    switch (selectedPeriod.value) {
      case StatsPeriod.week:
        const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final start = DateTimeUtils.startOfWeek(now);
        final secByDay = List<int>.filled(7, 0);
        for (final s in sessions) {
          final day = DateTimeUtils.startOfDay(
            DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
          );
          final idx = day.difference(start).inDays;
          if (idx >= 0 && idx < 7) {
            secByDay[idx] += s.durationSeconds;
          }
        }
        return List<StatBarBucket>.generate(
          7,
          (i) => StatBarBucket(label: labels[i], minutes: secByDay[i] ~/ 60),
        );

      case StatsPeriod.month:
        final secByWeek = List<int>.filled(5, 0);
        for (final s in sessions) {
          final local = DateTime.fromMillisecondsSinceEpoch(
            s.startedAtMs,
            isUtc: true,
          ).toLocal();
          final weekIdx = ((local.day - 1) ~/ 7).clamp(0, 4);
          secByWeek[weekIdx] += s.durationSeconds;
        }
        final currentWeekIdx = ((now.day - 1) ~/ 7).clamp(0, 4);
        return List<StatBarBucket>.generate(
          5,
          (i) => StatBarBucket(
            label: 'W${i + 1}',
            minutes: secByWeek[i] ~/ 60,
            isHighlighted: i <= currentWeekIdx,
          ),
        );

      case StatsPeriod.year:
        const monthShort = <String>[
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final secByMonth = List<int>.filled(12, 0);
        for (final s in sessions) {
          final local = DateTime.fromMillisecondsSinceEpoch(
            s.startedAtMs,
            isUtc: true,
          ).toLocal();
          secByMonth[local.month - 1] += s.durationSeconds;
        }
        return List<StatBarBucket>.generate(
          12,
          (i) => StatBarBucket(
            label: monthShort[i],
            minutes: secByMonth[i] ~/ 60,
          ),
        );
    }
  }

  List<SubjectSliceData> get subjectSlices {
    final sessions = periodSessions;
    if (sessions.isEmpty) {
      return <SubjectSliceData>[];
    }

    final secBySubject = <int?, int>{};
    for (final s in sessions) {
      secBySubject[s.subjectId] =
          (secBySubject[s.subjectId] ?? 0) + s.durationSeconds;
    }

    final totalSec = secBySubject.values.fold<int>(0, (a, b) => a + b);
    final entries = secBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return List<SubjectSliceData>.generate(entries.length, (idx) {
      final entry = entries[idx];
      final subject = _subjectForId(entry.key);
      final mins = entry.value ~/ 60;
      final pct = totalSec > 0 ? ((entry.value / totalSec) * 100).round() : 0;
      return SubjectSliceData(
        subjectId: entry.key,
        name: subject?.name ?? 'General Study',
        iconKey: subject?.iconKey ?? SubjectIconKey.book,
        minutes: mins,
        percentage: pct,
        paletteIndex: idx,
      );
    });
  }

  int get activityWindowDays =>
      selectedPeriod.value == StatsPeriod.year ? 30 : 14;

  List<DailyActivityPoint> get dailyActivityPoints {
    final daysCount = activityWindowDays;
    final today = DateTimeUtils.startOfDay(now);
    final startDate = today.subtract(Duration(days: daysCount - 1));
    final secByDateKey = <String, int>{};

    for (final s in allSessions) {
      final key = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      secByDateKey[key] = (secByDateKey[key] ?? 0) + s.durationSeconds;
    }

    return List<DailyActivityPoint>.generate(daysCount, (index) {
      final date = startDate.add(Duration(days: index));
      final key = DateTimeUtils.toDateKey(date);
      return DailyActivityPoint(
        date: date,
        minutes: (secByDateKey[key] ?? 0) ~/ 60,
      );
    });
  }

  SubjectSliceData? get mostStudiedSubject =>
      subjectSlices.isEmpty ? null : subjectSlices.first;

  String get bestStudyDayLabel {
    final sessions = periodSessions;
    if (sessions.isEmpty) {
      return '—';
    }
    const dayNames = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateTotals = <String, int>{};
    for (final s in sessions) {
      final key = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      dateTotals[key] = (dateTotals[key] ?? 0) + s.durationSeconds;
    }

    final weekdaySums = List<int>.filled(7, 0);
    final weekdayCounts = List<int>.filled(7, 0);
    for (final entry in dateTotals.entries) {
      final d = DateTimeUtils.parseDateKey(entry.key);
      final idx = d.weekday - 1;
      weekdaySums[idx] += entry.value;
      weekdayCounts[idx] += 1;
    }

    var bestIdx = 0;
    var bestAvgSec = -1.0;
    for (var i = 0; i < 7; i++) {
      if (weekdayCounts[i] == 0) {
        continue;
      }
      final avgSec = weekdaySums[i] / weekdayCounts[i];
      if (avgSec > bestAvgSec) {
        bestAvgSec = avgSec;
        bestIdx = i;
      }
    }
    if (bestAvgSec < 0) {
      return '—';
    }
    final avgMins = (bestAvgSec / 60).round();
    return '${dayNames[bestIdx]} · ${DateTimeUtils.formatMinutes(avgMins)} avg';
  }

  String get performanceSummaryText {
    final totalDays = switch (selectedPeriod.value) {
      StatsPeriod.week => 7,
      StatsPeriod.month => now.day,
      StatsPeriod.year =>
        math.max(1, now.difference(DateTime(now.year, 1, 1)).inDays + 1),
    };
    final scope = switch (selectedPeriod.value) {
      StatsPeriod.week => 'this week',
      StatsPeriod.month => 'this month',
      StatsPeriod.year => 'this year',
    };

    final weekStart = DateTimeUtils.startOfWeek(now).toUtc().millisecondsSinceEpoch;
    final weekEnd =
        DateTimeUtils.endOfWeekExclusive(now).toUtc().millisecondsSinceEpoch;
    final thisWeekMin = allSessions
            .where((s) => s.startedAtMs >= weekStart && s.startedAtMs < weekEnd)
            .fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/
        60;
    final goal = weeklyGoalMinutes.value;
    final goalPct = goal > 0 ? ((thisWeekMin / goal) * 100).round().clamp(0, 100) : 0;

    return 'You studied $studiedDaysCount of $totalDays days $scope and are $goalPct% of the way to your ${DateTimeUtils.formatMinutes(goal)} weekly goal.';
  }

  int get currentStreakDays => streakSummary.value?.currentStreak ?? 0;

  int get unlockedAchievementsCount =>
      achievements.where((a) => a.isUnlocked).length;

  int get totalAchievementsCount =>
      achievements.isEmpty ? 6 : achievements.length;

  SubjectEntity? _subjectForId(int? id) {
    if (id == null) {
      return null;
    }
    for (final s in allSubjects) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }

  @override
  void onClose() {
    _disposed = true;
    unawaited(_sessionsSub?.cancel());
    unawaited(_subjectsSub?.cancel());
    unawaited(_streakSub?.cancel());
    unawaited(_achievementsSub?.cancel());
    super.onClose();
  }
}
