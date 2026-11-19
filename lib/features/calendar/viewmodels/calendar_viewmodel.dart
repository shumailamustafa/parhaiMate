import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Calendar screen (11 Calendar.png & Month selector / Empty states).
class CalendarViewModel extends GetxController {
  CalendarViewModel({
    required SessionRepository sessionRepository,
    required PlannerRepository plannerRepository,
    required SubjectRepository subjectRepository,
    DateTime Function()? nowProvider,
  })  : _sessionRepository = sessionRepository,
        _plannerRepository = plannerRepository,
        _subjectRepository = subjectRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final SessionRepository _sessionRepository;
  final PlannerRepository _plannerRepository;
  final SubjectRepository _subjectRepository;
  final DateTime Function() _nowProvider;

  final RxList<StudySessionEntity> sessions = <StudySessionEntity>[].obs;
  final RxList<PlannerTaskEntity> tasks = <PlannerTaskEntity>[].obs;
  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  late final Rx<DateTime> displayedMonth;
  late final Rx<DateTime> selectedDate;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<List<PlannerTaskEntity>>? _tasksSub;
  StreamSubscription<List<SubjectEntity>>? _subjectsSub;

  @override
  void onInit() {
    super.onInit();
    final today = DateTimeUtils.startOfDay(_nowProvider());
    selectedDate = today.obs;
    displayedMonth = DateTime(today.year, today.month).obs;

    _sessionsSub = _sessionRepository.watchCompletedSessions().listen((data) {
      sessions.assignAll(data);
      isLoading.value = false;
    });
    _tasksSub = _plannerRepository.watchAllTasks().listen((data) {
      tasks.assignAll(data);
      isLoading.value = false;
    });
    _subjectsSub = _subjectRepository.watchSubjects().listen(subjects.assignAll);
  }

  DateTime get today => DateTimeUtils.startOfDay(_nowProvider());

  String get todayKey => DateTimeUtils.toDateKey(today);

  String get selectedDateKey => DateTimeUtils.toDateKey(selectedDate.value);

  String get monthTitle => DateTimeUtils.formatMonthYear(displayedMonth.value);

  String get selectedDateTitle =>
      DateTimeUtils.formatFullDate(selectedDate.value);

  Set<String> get studiedDateKeys => <String>{
        for (final s in sessions)
          DateTimeUtils.toDateKey(
            DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
          ),
      };

  Set<String> get plannedDateKeys => <String>{
        for (final t in tasks) t.scheduledDate,
      };

  void previousMonth() {
    final current = displayedMonth.value;
    displayedMonth.value = DateTime(current.year, current.month - 1);
  }

  void nextMonth() {
    final current = displayedMonth.value;
    displayedMonth.value = DateTime(current.year, current.month + 1);
  }

  void selectMonthYear(int year, int month) {
    displayedMonth.value = DateTime(year, month);
  }

  void selectDate(DateTime date) {
    selectedDate.value = DateTimeUtils.startOfDay(date);
  }

  List<PlannerTaskEntity> get tasksForSelectedDate {
    final key = selectedDateKey;
    final list = tasks.where((t) => t.scheduledDate == key).toList();
    list.sort((a, b) => (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? ''));
    return list;
  }

  List<PlannerTaskEntity> get scheduledTasksForSelectedDate =>
      tasksForSelectedDate.where((t) => !t.isCompleted).toList();

  List<PlannerTaskEntity> get completedTasksForSelectedDate =>
      tasksForSelectedDate.where((t) => t.isCompleted).toList();

  List<StudySessionEntity> get sessionsForSelectedDate {
    final key = selectedDateKey;
    return sessions.where((s) {
      final sessionKey = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      return sessionKey == key;
    }).toList();
  }

  int get studiedMinutesForSelectedDate {
    final totalSec = sessionsForSelectedDate.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    return totalSec ~/ 60;
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
    unawaited(_sessionsSub?.cancel());
    unawaited(_tasksSub?.cancel());
    unawaited(_subjectsSub?.cancel());
    super.onClose();
  }
}
