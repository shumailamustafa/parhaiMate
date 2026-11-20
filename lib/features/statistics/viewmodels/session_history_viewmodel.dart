import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

class SessionHistoryDayGroup {
  const SessionHistoryDayGroup({
    required this.dateKey,
    required this.heading,
    required this.totalLabel,
    required this.sessions,
  });

  final String dateKey;
  final String heading;
  final String totalLabel;
  final List<StudySessionEntity> sessions;
}

/// ViewModel for Session History screen (Session History.png & Empty state).
class SessionHistoryViewModel extends GetxController {
  SessionHistoryViewModel({
    required SessionRepository sessionRepository,
    required SubjectRepository subjectRepository,
    int? initialSubjectId,
    DateTime Function()? nowProvider,
  })  : _sessionRepository = sessionRepository,
        _subjectRepository = subjectRepository,
        _initialSubjectId = initialSubjectId,
        _nowProvider = nowProvider ?? DateTime.now;

  final SessionRepository _sessionRepository;
  final SubjectRepository _subjectRepository;
  final int? _initialSubjectId;
  final DateTime Function() _nowProvider;

  final RxList<StudySessionEntity> allSessions = <StudySessionEntity>[].obs;
  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  final RxnInt selectedSubjectId = RxnInt();
  final RxBool newestFirst = true.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<List<SubjectEntity>>? _subjectsSub;

  @override
  void onInit() {
    super.onInit();
    final arg = _initialSubjectId ?? Get.arguments;
    if (arg is int) {
      selectedSubjectId.value = arg;
    }

    _sessionsSub = _sessionRepository.watchCompletedSessions().listen((data) {
      allSessions.assignAll(data);
      isLoading.value = false;
    });
    _subjectsSub = _subjectRepository.watchSubjects().listen(subjects.assignAll);
  }

  void selectSubjectFilter(int? subjectId) {
    selectedSubjectId.value = subjectId;
  }

  void toggleSortOrder() {
    newestFirst.value = !newestFirst.value;
  }

  String get sortLabel => newestFirst.value ? 'Newest first' : 'Oldest first';

  List<StudySessionEntity> get filteredSessions {
    final filterId = selectedSubjectId.value;
    final list = filterId == null
        ? allSessions.toList()
        : allSessions.where((s) => s.subjectId == filterId).toList();

    list.sort((a, b) => newestFirst.value
        ? b.startedAtMs.compareTo(a.startedAtMs)
        : a.startedAtMs.compareTo(b.startedAtMs));
    return list;
  }

  List<SessionHistoryDayGroup> get groupedSessions {
    final list = filteredSessions;
    final grouped = <String, List<StudySessionEntity>>{};
    for (final s in list) {
      final key = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      grouped.putIfAbsent(key, () => <StudySessionEntity>[]).add(s);
    }

    final today = DateTimeUtils.startOfDay(_nowProvider());
    final yesterday = today.subtract(const Duration(days: 1));
    final todayKey = DateTimeUtils.toDateKey(today);
    final yesterdayKey = DateTimeUtils.toDateKey(yesterday);

    return grouped.entries.map((entry) {
      final key = entry.key;
      final heading = key == todayKey
          ? 'Today'
          : (key == yesterdayKey
              ? 'Yesterday'
              : DateTimeUtils.formatShortDate(DateTimeUtils.parseDateKey(key)));
      final totalSec = entry.value.fold<int>(
        0,
        (sum, s) => sum + s.durationSeconds,
      );
      return SessionHistoryDayGroup(
        dateKey: key,
        heading: heading,
        totalLabel: DateTimeUtils.formatSecondsAsMinutesLabel(totalSec),
        sessions: entry.value,
      );
    }).toList();
  }

  SubjectEntity? subjectForId(int? id) {
    if (id == null) {
      return null;
    }
    for (final s in subjects) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }

  @override
  void onClose() {
    unawaited(_sessionsSub?.cancel());
    unawaited(_subjectsSub?.cancel());
    super.onClose();
  }
}
