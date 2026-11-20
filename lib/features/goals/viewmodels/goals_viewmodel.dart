import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

enum HeatmapCellState { studied, missed, upcoming }

class HeatmapDayCell {
  const HeatmapDayCell({
    required this.date,
    required this.state,
    required this.isToday,
  });

  final DateTime date;
  final HeatmapCellState state;
  final bool isToday;
}

/// ViewModel for Goals & Streaks screen (13 Goals & Streaks.png & Edited.png).
class GoalsViewModel extends GetxController {
  GoalsViewModel({
    required GoalStreakRepository goalStreakRepository,
    required SessionRepository sessionRepository,
    DateTime Function()? nowProvider,
  })  : _goalStreakRepository = goalStreakRepository,
        _sessionRepository = sessionRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  static const int minDailyMinutes = 30;
  static const int maxDailyMinutes = 720;
  static const int dailyStepMinutes = 30;
  static const int minWeeklyMinutes = 60;
  static const int maxWeeklyMinutes = 5040;
  static const int weeklyStepMinutes = 60;

  final GoalStreakRepository _goalStreakRepository;
  final SessionRepository _sessionRepository;
  final DateTime Function() _nowProvider;

  final RxList<StudySessionEntity> completedSessions =
      <StudySessionEntity>[].obs;
  final Rxn<StreakSummaryEntity> streakSummary = Rxn<StreakSummaryEntity>();
  final RxInt savedDailyMinutes = 240.obs;
  final RxInt savedWeeklyMinutes = 1200.obs;
  final RxInt draftDailyMinutes = 240.obs;
  final RxInt draftWeeklyMinutes = 1200.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<StreakSummaryEntity>? _streakSub;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _sessionsSub = _sessionRepository.watchCompletedSessions().listen((data) {
      completedSessions.assignAll(data);
      isLoading.value = false;
    });
    _streakSub = _goalStreakRepository.watchStreakSummary().listen((summary) {
      streakSummary.value = summary;
    });
    unawaited(_loadSavedGoals());
  }

  Future<void> _loadSavedGoals() async {
    final todayKey = DateTimeUtils.toDateKey(_nowProvider());
    final daily =
        await _goalStreakRepository.getDailyGoalMinutes(dateKey: todayKey);
    final weekly = await _goalStreakRepository.getWeeklyGoalMinutes();
    if (!_disposed) {
      savedDailyMinutes.value = daily;
      savedWeeklyMinutes.value = weekly;
      draftDailyMinutes.value = daily;
      draftWeeklyMinutes.value = weekly;
      isLoading.value = false;
    }
  }

  DateTime get today => DateTimeUtils.startOfDay(_nowProvider());

  bool get hasUnsavedChanges =>
      draftDailyMinutes.value != savedDailyMinutes.value ||
      draftWeeklyMinutes.value != savedWeeklyMinutes.value;

  void adjustDailyGoal(int delta) {
    draftDailyMinutes.value =
        (draftDailyMinutes.value + delta).clamp(minDailyMinutes, maxDailyMinutes);
  }

  void adjustWeeklyGoal(int delta) {
    draftWeeklyMinutes.value = (draftWeeklyMinutes.value + delta)
        .clamp(minWeeklyMinutes, maxWeeklyMinutes);
  }

  int get todayStudiedMinutes {
    final todayKey = DateTimeUtils.toDateKey(today);
    var totalSec = 0;
    for (final s in completedSessions) {
      final key = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      if (key == todayKey) {
        totalSec += s.durationSeconds;
      }
    }
    return totalSec ~/ 60;
  }

  int get dailyRemainingMinutes =>
      math.max(0, draftDailyMinutes.value - todayStudiedMinutes);

  int get dailyProgressPercent {
    final target = draftDailyMinutes.value;
    if (target <= 0) {
      return 0;
    }
    return ((todayStudiedMinutes / target) * 100).round().clamp(0, 100);
  }

  double get dailyProgressFraction {
    final target = draftDailyMinutes.value;
    if (target <= 0) {
      return 0;
    }
    return (todayStudiedMinutes / target).clamp(0.0, 1.0);
  }

  int get weekStudiedMinutes {
    final start = DateTimeUtils.startOfWeek(today).toUtc().millisecondsSinceEpoch;
    final end =
        DateTimeUtils.endOfWeekExclusive(today).toUtc().millisecondsSinceEpoch;
    var totalSec = 0;
    for (final s in completedSessions) {
      if (s.startedAtMs >= start && s.startedAtMs < end) {
        totalSec += s.durationSeconds;
      }
    }
    return totalSec ~/ 60;
  }

  int get weeklyRemainingMinutes =>
      math.max(0, draftWeeklyMinutes.value - weekStudiedMinutes);

  double get weeklyProgressFraction {
    final target = draftWeeklyMinutes.value;
    if (target <= 0) {
      return 0;
    }
    return (weekStudiedMinutes / target).clamp(0.0, 1.0);
  }

  int get daysRemainingInWeek => math.max(0, 7 - today.weekday);

  int get currentStreak => streakSummary.value?.currentStreak ?? 0;

  int get longestStreak => streakSummary.value?.longestStreak ?? 0;

  /// Builds 4 weeks x 7 Mon-Sun days ending on Sunday of the current week.
  List<HeatmapDayCell> get heatmapCells {
    final currentWeekStart = DateTimeUtils.startOfWeek(today);
    final gridStart = currentWeekStart.subtract(const Duration(days: 21));
    final todayKey = DateTimeUtils.toDateKey(today);

    final qualifiedKeys = <String>{
      for (final s in completedSessions)
        if (s.durationSeconds > 0)
          DateTimeUtils.toDateKey(
            DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
          ),
    };
    final records = streakSummary.value?.recordsByDate ?? const {};
    for (final entry in records.entries) {
      if (entry.value.streakQualified) {
        qualifiedKeys.add(entry.key);
      }
    }

    return List<HeatmapDayCell>.generate(28, (index) {
      final date = gridStart.add(Duration(days: index));
      final key = DateTimeUtils.toDateKey(date);
      final isToday = key == todayKey;
      final isFuture = date.isAfter(today);

      final HeatmapCellState state;
      if (qualifiedKeys.contains(key)) {
        state = HeatmapCellState.studied;
      } else if (isFuture || isToday) {
        state = HeatmapCellState.upcoming;
      } else {
        state = HeatmapCellState.missed;
      }
      return HeatmapDayCell(date: date, state: state, isToday: isToday);
    });
  }

  Future<void> saveChanges() async {
    if (!hasUnsavedChanges || isSaving.value) {
      return;
    }
    isSaving.value = true;
    try {
      final daily = draftDailyMinutes.value;
      final weekly = draftWeeklyMinutes.value;
      final todayKey = DateTimeUtils.toDateKey(today);
      await _goalStreakRepository.setDailyGoalMinutes(daily, dateKey: todayKey);
      await _goalStreakRepository.setWeeklyGoalMinutes(weekly);
      if (!_disposed) {
        savedDailyMinutes.value = daily;
        savedWeeklyMinutes.value = weekly;
      }
    } finally {
      if (!_disposed) {
        isSaving.value = false;
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    unawaited(_sessionsSub?.cancel());
    unawaited(_streakSub?.cancel());
    super.onClose();
  }
}
