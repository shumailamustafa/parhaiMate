import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

enum PlannerTab { day, upcoming, completed }

class PlannerTaskGroup {
  const PlannerTaskGroup({
    required this.dateKey,
    required this.heading,
    required this.tasks,
  });

  final String dateKey;
  final String heading;
  final List<PlannerTaskEntity> tasks;
}

/// ViewModel for Study Planner (10 Study Planner.png & empty/tab states).
class PlannerViewModel extends GetxController {
  PlannerViewModel({
    required PlannerRepository plannerRepository,
    required SubjectRepository subjectRepository,
    DateTime Function()? nowProvider,
  })  : _plannerRepository = plannerRepository,
        _subjectRepository = subjectRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final PlannerRepository _plannerRepository;
  final SubjectRepository _subjectRepository;
  final DateTime Function() _nowProvider;

  final RxList<PlannerTaskEntity> allTasks = <PlannerTaskEntity>[].obs;
  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  late final Rx<DateTime> selectedDate;
  late final Rx<DateTime> focusedWeekStart;
  final Rx<PlannerTab> activeTab = PlannerTab.day.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<PlannerTaskEntity>>? _tasksSub;
  StreamSubscription<List<SubjectEntity>>? _subjectsSub;

  @override
  void onInit() {
    super.onInit();
    final today = DateTimeUtils.startOfDay(_nowProvider());
    selectedDate = today.obs;
    focusedWeekStart = DateTimeUtils.startOfWeek(today).obs;

    _tasksSub = _plannerRepository.watchAllTasks().listen((data) {
      allTasks.assignAll(data);
      isLoading.value = false;
    });
    _subjectsSub = _subjectRepository.watchSubjects().listen(subjects.assignAll);
  }

  DateTime get today => DateTimeUtils.startOfDay(_nowProvider());

  String get todayKey => DateTimeUtils.toDateKey(today);

  String get selectedDateKey => DateTimeUtils.toDateKey(selectedDate.value);

  bool get isSelectedToday => selectedDateKey == todayKey;

  String get dayTabLabel => isSelectedToday
      ? 'Today'
      : DateFormat('EEE, d MMM').format(selectedDate.value);

  String get weekRangeLabel {
    final start = focusedWeekStart.value;
    final end = start.add(const Duration(days: 6));
    final startStr = DateFormat('d MMM').format(start);
    final endStr = DateFormat('d MMM').format(end);
    return '$startStr – $endStr';
  }

  List<PmWeekDayItem> get weekDays {
    final start = focusedWeekStart.value;
    final taskDateKeys = <String>{
      for (final task in allTasks) task.scheduledDate,
    };

    return List<PmWeekDayItem>.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final key = DateTimeUtils.toDateKey(date);
      return PmWeekDayItem(
        date: date,
        dayShort: DateFormat('E').format(date),
        dayNumber: '${date.day}',
        hasActivity: taskDateKeys.contains(key),
        isToday: key == todayKey,
      );
    });
  }

  void previousWeek() {
    focusedWeekStart.value =
        focusedWeekStart.value.subtract(const Duration(days: 7));
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    focusedWeekStart.value = focusedWeekStart.value.add(const Duration(days: 7));
    selectedDate.value = selectedDate.value.add(const Duration(days: 7));
  }

  void selectDate(DateTime date) {
    final normalized = DateTimeUtils.startOfDay(date);
    selectedDate.value = normalized;
    focusedWeekStart.value = DateTimeUtils.startOfWeek(normalized);
    activeTab.value = PlannerTab.day;
  }

  void setTab(PlannerTab tab) {
    activeTab.value = tab;
  }

  List<PlannerTaskEntity> get tasksForSelectedDate {
    final key = selectedDateKey;
    final list = allTasks.where((t) => t.scheduledDate == key).toList();
    list.sort((a, b) => (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? ''));
    return list;
  }

  List<PlannerTaskEntity> get pendingForSelectedDate =>
      tasksForSelectedDate.where((t) => !t.isCompleted).toList();

  List<PlannerTaskEntity> get completedForSelectedDate =>
      tasksForSelectedDate.where((t) => t.isCompleted).toList();

  String get daySummaryLabel {
    final dayTasks = tasksForSelectedDate;
    final done = dayTasks.where((t) => t.isCompleted).length;
    final plannedMinutes = dayTasks.fold<int>(
      0,
      (sum, t) => sum + t.targetMinutes,
    );
    return '$done of ${dayTasks.length} tasks done · ${DateTimeUtils.formatMinutes(plannedMinutes)} planned';
  }

  List<PlannerTaskGroup> get upcomingGroups {
    final currentTodayKey = todayKey;
    final list = allTasks
        .where(
          (t) =>
              !t.isCompleted &&
              t.scheduledDate.compareTo(currentTodayKey) > 0,
        )
        .toList();
    list.sort((a, b) {
      final dateCmp = a.scheduledDate.compareTo(b.scheduledDate);
      if (dateCmp != 0) {
        return dateCmp;
      }
      return (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? '');
    });
    return _groupTasksByDate(list);
  }

  List<PlannerTaskGroup> get completedGroups {
    final list = allTasks.where((t) => t.isCompleted).toList();
    list.sort((a, b) {
      final dateCmp = b.scheduledDate.compareTo(a.scheduledDate);
      if (dateCmp != 0) {
        return dateCmp;
      }
      return b.updatedAtMs.compareTo(a.updatedAtMs);
    });
    return _groupTasksByDate(list);
  }

  List<PlannerTaskGroup> _groupTasksByDate(List<PlannerTaskEntity> tasks) {
    final map = <String, List<PlannerTaskEntity>>{};
    for (final task in tasks) {
      map.putIfAbsent(task.scheduledDate, () => <PlannerTaskEntity>[]).add(task);
    }

    return map.entries
        .map(
          (entry) => PlannerTaskGroup(
            dateKey: entry.key,
            heading: relativeDateHeading(entry.key),
            tasks: entry.value,
          ),
        )
        .toList();
  }

  String relativeDateHeading(String dateKey) {
    final date = DateTimeUtils.parseDateKey(dateKey);
    final t = today;
    final tomorrow = t.add(const Duration(days: 1));
    final yesterday = t.subtract(const Duration(days: 1));
    if (DateTimeUtils.toDateKey(date) == DateTimeUtils.toDateKey(t)) {
      return 'Today';
    }
    if (DateTimeUtils.toDateKey(date) == DateTimeUtils.toDateKey(tomorrow)) {
      return 'Tomorrow';
    }
    if (DateTimeUtils.toDateKey(date) == DateTimeUtils.toDateKey(yesterday)) {
      return 'Yesterday';
    }
    return DateTimeUtils.formatShortDate(date);
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
    unawaited(_tasksSub?.cancel());
    unawaited(_subjectsSub?.cancel());
    super.onClose();
  }
}
