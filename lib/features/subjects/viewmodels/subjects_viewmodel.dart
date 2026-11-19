import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for My Subjects list, search, Active/Archived toggle, and weekly stats.
class SubjectsViewModel extends GetxController {
  SubjectsViewModel({
    required SubjectRepository subjectRepository,
    required SessionRepository sessionRepository,
    DateTime Function()? nowProvider,
  })  : _subjectRepository = subjectRepository,
        _sessionRepository = sessionRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final SubjectRepository _subjectRepository;
  final SessionRepository _sessionRepository;
  final DateTime Function() _nowProvider;

  final TextEditingController searchController = TextEditingController();

  final RxList<SubjectEntity> allSubjects = <SubjectEntity>[].obs;
  final RxList<StudySessionEntity> completedSessions =
      <StudySessionEntity>[].obs;
  final RxBool showArchived = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    _subjectsSub = _subjectRepository.watchSubjects().listen((data) {
      allSubjects.assignAll(data);
      isLoading.value = false;
    });
    _sessionsSub = _sessionRepository.watchCompletedSessions().listen((data) {
      completedSessions.assignAll(data);
      isLoading.value = false;
    });
  }

  List<SubjectEntity> get activeSubjects =>
      allSubjects.where((s) => !s.isArchived).toList();

  List<SubjectEntity> get archivedSubjects =>
      allSubjects.where((s) => s.isArchived).toList();

  List<SubjectEntity> get tabSubjects =>
      showArchived.value ? archivedSubjects : activeSubjects;

  List<SubjectEntity> get filteredSubjects {
    final query = searchQuery.value.trim().toLowerCase();
    final source = tabSubjects;
    if (query.isEmpty) {
      return source;
    }
    return source
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
  }

  void setShowArchived(bool archived) {
    showArchived.value = archived;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  int totalMinutesForSubject(int subjectId) {
    var totalSeconds = 0;
    for (final s in completedSessions) {
      if (s.subjectId == subjectId) {
        totalSeconds += s.durationSeconds;
      }
    }
    return totalSeconds ~/ 60;
  }

  int weekMinutesForSubject(int subjectId) {
    final now = _nowProvider();
    final startMs = DateTimeUtils.startOfWeek(now).toUtc().millisecondsSinceEpoch;
    final endMs =
        DateTimeUtils.endOfWeekExclusive(now).toUtc().millisecondsSinceEpoch;

    var totalSeconds = 0;
    for (final s in completedSessions) {
      if (s.subjectId == subjectId &&
          s.startedAtMs >= startMs &&
          s.startedAtMs < endMs) {
        totalSeconds += s.durationSeconds;
      }
    }
    return totalSeconds ~/ 60;
  }

  int get totalWeekMinutesInCurrentTab {
    var total = 0;
    for (final subject in filteredSubjects) {
      total += weekMinutesForSubject(subject.id);
    }
    return total;
  }

  String get tabSummaryLabel {
    final count = filteredSubjects.length;
    final subjectWord = count == 1 ? 'subject' : 'subjects';
    final weekLabel = DateTimeUtils.formatMinutes(totalWeekMinutesInCurrentTab);
    return '$count $subjectWord · $weekLabel this week';
  }

  @override
  void onClose() {
    unawaited(_subjectsSub?.cancel());
    unawaited(_sessionsSub?.cancel());
    searchController.dispose();
    super.onClose();
  }
}
