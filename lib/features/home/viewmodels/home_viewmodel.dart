import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/pm_inputs.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

class HomeViewModel extends GetxController {
  HomeViewModel({
    required SubjectRepository subjectRepository,
    required SessionRepository sessionRepository,
    required PlannerRepository plannerRepository,
    required GoalStreakRepository goalStreakRepository,
    DateTime Function()? nowProvider,
  })  : _subjectRepository = subjectRepository,
        _sessionRepository = sessionRepository,
        _plannerRepository = plannerRepository,
        _goalStreakRepository = goalStreakRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final SubjectRepository _subjectRepository;
  final SessionRepository _sessionRepository;
  final PlannerRepository _plannerRepository;
  final GoalStreakRepository _goalStreakRepository;
  final DateTime Function() _nowProvider;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxInt dailyTargetMinutes = 240.obs;
  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  final RxList<StudySessionEntity> completedSessions = <StudySessionEntity>[].obs;
  final RxList<PlannerTaskEntity> allTasks = <PlannerTaskEntity>[].obs;
  final Rxn<StreakSummaryEntity> streakSummary = Rxn<StreakSummaryEntity>();
  final RxBool isLoading = true.obs;

  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<List<PlannerTaskEntity>>? _tasksSub;
  StreamSubscription<StreakSummaryEntity>? _streakSub;

  @override
  void onInit() {
    super.onInit();
    selectedDate.value = DateTimeUtils.startOfDay(_nowProvider());
    _subjectsSub = _subjectRepository.watchSubjects().listen((data) {
      subjects.assignAll(data);
      isLoading.value = false;
    });
    _sessionsSub = _sessionRepository.watchCompletedSessions().listen((data) {
      completedSessions.assignAll(data);
      isLoading.value = false;
    });
    _tasksSub = _plannerRepository.watchAllTasks().listen((data) {
      allTasks.assignAll(data);
      isLoading.value = false;
    });
    _streakSub = _goalStreakRepository.watchStreakSummary().listen((data) {
      streakSummary.value = data;
    });
    unawaited(refreshGoals());
  }

  Future<void> refreshGoals() async {
    final key = DateTimeUtils.toDateKey(selectedDate.value);
    dailyTargetMinutes.value =
        await _goalStreakRepository.getDailyGoalMinutes(dateKey: key);
  }

  void selectDate(DateTime date) {
    selectedDate.value = DateTimeUtils.startOfDay(date);
    unawaited(refreshGoals());
  }

  String get greeting => DateTimeUtils.greetingForHour(_nowProvider().hour);

  String get selectedDateTitle =>
      DateTimeUtils.formatFullDate(selectedDate.value);

  bool get isSelectedToday =>
      DateTimeUtils.toDateKey(selectedDate.value) ==
      DateTimeUtils.toDateKey(_nowProvider());

  String get selectedDateKey => DateTimeUtils.toDateKey(selectedDate.value);

  List<PmWeekDayItem> get weekDays {
    final weekStart = DateTimeUtils.startOfWeek(selectedDate.value);
    final todayKey = DateTimeUtils.toDateKey(_nowProvider());

    final activeDateKeys = <String>{
      for (final s in completedSessions)
        DateTimeUtils.toDateKey(
          DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
        ),
      for (final t in allTasks) t.scheduledDate,
    };

    return List<PmWeekDayItem>.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final key = DateTimeUtils.toDateKey(date);
      return PmWeekDayItem(
        date: date,
        dayShort: DateFormat('E').format(date),
        dayNumber: '${date.day}',
        hasActivity: activeDateKeys.contains(key),
        isToday: key == todayKey,
      );
    });
  }

  List<StudySessionEntity> get sessionsForSelectedDate {
    final targetKey = selectedDateKey;
    return completedSessions.where((session) {
      final localKey = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(session.startedAtMs, isUtc: true),
      );
      return localKey == targetKey;
    }).toList();
  }

  int get studiedSecondsForSelectedDate => sessionsForSelectedDate.fold<int>(
        0,
        (sum, s) => sum + s.durationSeconds,
      );

  int get studiedMinutesForSelectedDate => studiedSecondsForSelectedDate ~/ 60;

  double get dailyProgressFraction {
    final target = dailyTargetMinutes.value;
    if (target <= 0) {
      return 0;
    }
    return (studiedMinutesForSelectedDate / target).clamp(0.0, 1.0);
  }

  int get dailyProgressPercent {
    final target = dailyTargetMinutes.value;
    if (target <= 0) {
      return 0;
    }
    return ((studiedMinutesForSelectedDate / target) * 100).round().clamp(0, 100);
  }

  String get studiedDurationLabel =>
      DateTimeUtils.formatMinutes(studiedMinutesForSelectedDate);

  String get targetDurationLabel =>
      'of ${DateTimeUtils.formatMinutes(dailyTargetMinutes.value)} target';

  String get remainingDurationLabel {
    final rem = math.max(
      0,
      dailyTargetMinutes.value - studiedMinutesForSelectedDate,
    );
    return DateTimeUtils.formatMinutes(rem);
  }

  int get sessionsCountForSelectedDate => sessionsForSelectedDate.length;

  int get weekStudiedMinutes {
    final start = DateTimeUtils.startOfWeek(selectedDate.value)
        .toUtc()
        .millisecondsSinceEpoch;
    final end = DateTimeUtils.endOfWeekExclusive(selectedDate.value)
        .toUtc()
        .millisecondsSinceEpoch;
    var totalSeconds = 0;
    for (final s in completedSessions) {
      if (s.startedAtMs >= start && s.startedAtMs < end) {
        totalSeconds += s.durationSeconds;
      }
    }
    return totalSeconds ~/ 60;
  }

  String get focusTimeThisWeekLabel =>
      DateTimeUtils.formatMinutes(weekStudiedMinutes);

  int get currentStreakDays => streakSummary.value?.currentStreak ?? 0;

  List<PlannerTaskEntity> get tasksForSelectedDate {
    final targetKey = selectedDateKey;
    final list = allTasks
        .where((task) => task.scheduledDate == targetKey)
        .toList();
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? '');
    });
    return list;
  }

  List<StudySessionEntity> get recentSessions {
    if (completedSessions.length <= 3) {
      return completedSessions.toList();
    }
    return completedSessions.take(3).toList();
  }

  SubjectEntity? subjectForId(int? subjectId) {
    if (subjectId == null) {
      return null;
    }
    for (final s in subjects) {
      if (s.id == subjectId) {
        return s;
      }
    }
    return null;
  }

  Future<void> toggleTask(PlannerTaskEntity task) {
    return _plannerRepository.toggleTaskCompletion(
      task.id,
      isCompleted: !task.isCompleted,
    );
  }

  @override
  void onClose() {
    unawaited(_subjectsSub?.cancel());
    unawaited(_sessionsSub?.cancel());
    unawaited(_tasksSub?.cancel());
    unawaited(_streakSub?.cancel());
    super.onClose();
  }
}
