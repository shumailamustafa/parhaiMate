import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// Shared ViewModel backing Daily Goal Configuration & Weekly Goal Configuration screens.
class GoalConfigViewModel extends GetxController {
  GoalConfigViewModel({
    required GoalStreakRepository goalStreakRepository,
    required SessionRepository sessionRepository,
    DateTime Function()? nowProvider,
  })  : _goalRepo = goalStreakRepository,
        _sessionRepo = sessionRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  static const int minDailyMinutes = 30;
  static const int maxDailyMinutes = 720;
  static const int dailyStep = 30;
  static const List<int> dailyPresetHours = <int>[1, 2, 3, 4, 5, 6];

  static const int minWeeklyMinutes = 60;
  static const int maxWeeklyMinutes = 5040;
  static const int weeklyStep = 60;
  static const List<int> weeklyPresetHours = <int>[10, 15, 20, 25, 30];

  final GoalStreakRepository _goalRepo;
  final SessionRepository _sessionRepo;
  final DateTime Function() _nowProvider;

  final RxInt savedDailyMinutes = 240.obs;
  final RxInt draftDailyMinutes = 240.obs;
  final RxInt savedWeeklyMinutes = 1200.obs;
  final RxInt draftWeeklyMinutes = 1200.obs;
  final RxInt todayStudiedMinutes = 0.obs;
  final RxInt weekStudiedMinutes = 0.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _sessionsSub = _sessionRepo.watchCompletedSessions().listen((sessions) {
      final now = _nowProvider();
      final todayKey = DateTimeUtils.toDateKey(now);
      final weekStart =
          DateTimeUtils.startOfWeek(now).toUtc().millisecondsSinceEpoch;
      final weekEnd =
          DateTimeUtils.endOfWeekExclusive(now).toUtc().millisecondsSinceEpoch;

      var todaySec = 0;
      var weekSec = 0;
      for (final s in sessions) {
        final key = DateTimeUtils.toDateKey(
          DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
        );
        if (key == todayKey) {
          todaySec += s.durationSeconds;
        }
        if (s.startedAtMs >= weekStart && s.startedAtMs < weekEnd) {
          weekSec += s.durationSeconds;
        }
      }
      todayStudiedMinutes.value = todaySec ~/ 60;
      weekStudiedMinutes.value = weekSec ~/ 60;
    });
    unawaited(_loadGoals());
  }

  Future<void> _loadGoals() async {
    final todayKey = DateTimeUtils.toDateKey(_nowProvider());
    final daily = await _goalRepo.getDailyGoalMinutes(dateKey: todayKey);
    final weekly = await _goalRepo.getWeeklyGoalMinutes();
    if (!_disposed) {
      savedDailyMinutes.value = daily;
      draftDailyMinutes.value = daily;
      savedWeeklyMinutes.value = weekly;
      draftWeeklyMinutes.value = weekly;
      isLoading.value = false;
    }
  }

  bool get hasDailyChanges => draftDailyMinutes.value != savedDailyMinutes.value;

  bool get hasWeeklyChanges =>
      draftWeeklyMinutes.value != savedWeeklyMinutes.value;

  void adjustDailyMinutes(int delta) {
    draftDailyMinutes.value =
        (draftDailyMinutes.value + delta).clamp(minDailyMinutes, maxDailyMinutes);
  }

  void setDailyMinutes(int minutes) {
    draftDailyMinutes.value = minutes.clamp(minDailyMinutes, maxDailyMinutes);
  }

  void adjustWeeklyMinutes(int delta) {
    draftWeeklyMinutes.value = (draftWeeklyMinutes.value + delta)
        .clamp(minWeeklyMinutes, maxWeeklyMinutes);
  }

  void setWeeklyMinutes(int minutes) {
    draftWeeklyMinutes.value = minutes.clamp(minWeeklyMinutes, maxWeeklyMinutes);
  }

  int get dailyComparisonPercent {
    final target = draftDailyMinutes.value;
    if (target <= 0) {
      return 0;
    }
    return ((todayStudiedMinutes.value / target) * 100).round().clamp(0, 100);
  }

  String get dailySummaryBanner =>
      "Today you've studied ${DateTimeUtils.formatMinutes(todayStudiedMinutes.value)}, $dailyComparisonPercent% of this goal";

  String get weeklyDailyAverageLabel {
    final avgMin = (draftWeeklyMinutes.value / 7).round();
    return "That's about ${DateTimeUtils.formatMinutes(avgMin)} a day";
  }

  String get weeklyStudiedBanner =>
      'This week so far: ${DateTimeUtils.formatMinutes(weekStudiedMinutes.value)}';

  Future<void> saveDailyGoal() async {
    if (!hasDailyChanges || isSaving.value) {
      return;
    }
    isSaving.value = true;
    try {
      final todayKey = DateTimeUtils.toDateKey(_nowProvider());
      await _goalRepo.setDailyGoalMinutes(
        draftDailyMinutes.value,
        dateKey: todayKey,
      );
      if (!_disposed) {
        savedDailyMinutes.value = draftDailyMinutes.value;
      }
    } finally {
      if (!_disposed) {
        isSaving.value = false;
      }
    }
  }

  Future<void> saveWeeklyGoal() async {
    if (!hasWeeklyChanges || isSaving.value) {
      return;
    }
    isSaving.value = true;
    try {
      await _goalRepo.setWeeklyGoalMinutes(draftWeeklyMinutes.value);
      if (!_disposed) {
        savedWeeklyMinutes.value = draftWeeklyMinutes.value;
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
    super.onClose();
  }
}
