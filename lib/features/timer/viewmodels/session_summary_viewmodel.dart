import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Session Summary screen (07 Session Summary.png & Add notes sheet).
class SessionSummaryViewModel extends GetxController {
  SessionSummaryViewModel({
    required SessionRepository sessionRepository,
    required SubjectRepository subjectRepository,
    required GoalStreakRepository goalStreakRepository,
    required TimerEngineService timerEngine,
    int? initialSessionId,
  })  : _sessionRepository = sessionRepository,
        _subjectRepository = subjectRepository,
        _goalStreakRepository = goalStreakRepository,
        _timerEngine = timerEngine,
        _initialSessionId = initialSessionId;

  final SessionRepository _sessionRepository;
  final SubjectRepository _subjectRepository;
  final GoalStreakRepository _goalStreakRepository;
  final TimerEngineService _timerEngine;
  final int? _initialSessionId;

  final TextEditingController notesController = TextEditingController();

  final Rxn<StudySessionEntity> session = Rxn<StudySessionEntity>();
  final RxString subjectName = 'General Study'.obs;
  final RxInt todayStudiedMinutes = 0.obs;
  final RxInt dailyGoalMinutes = 240.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSavingNotes = false.obs;

  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final arg = _initialSessionId ?? Get.arguments;
      StudySessionEntity? target;

      if (arg is int) {
        target = await _sessionRepository.getById(arg);
      } else if (arg is StudySessionEntity) {
        target = arg;
      }

      target ??= _timerEngine.lastCompletedSession.value;
      if (target == null) {
        final all = await _sessionRepository.getCompletedSessions();
        if (all.isNotEmpty) {
          target = all.first;
        }
      }

      if (_disposed || target == null) {
        return;
      }

      session.value = target;
      notesController.text = target.notes ?? '';

      if (target.subjectId != null) {
        final subject = await _subjectRepository.getById(target.subjectId!);
        if (!_disposed && subject != null) {
          subjectName.value = subject.name;
        }
      } else {
        subjectName.value = 'General Study';
      }

      final sessionLocalDate = DateTime.fromMillisecondsSinceEpoch(
        target.startedAtMs,
        isUtc: true,
      ).toLocal();
      final dayStart = DateTimeUtils.startOfDay(sessionLocalDate);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dateKey = DateTimeUtils.toDateKey(dayStart);

      final goal = await _goalStreakRepository.getDailyGoalMinutes(
        dateKey: dateKey,
      );
      final daySessions = await _sessionRepository.getCompletedSessions(
        startMsInclusive: dayStart.toUtc().millisecondsSinceEpoch,
        endMsExclusive: dayEnd.toUtc().millisecondsSinceEpoch,
      );

      final totalSeconds = daySessions.fold<int>(
        0,
        (sum, s) => sum + s.durationSeconds,
      );

      if (!_disposed) {
        dailyGoalMinutes.value = goal;
        todayStudiedMinutes.value = totalSeconds ~/ 60;
      }
    } finally {
      if (!_disposed) {
        isLoading.value = false;
      }
    }
  }

  String get durationLabel {
    final s = session.value;
    if (s == null) {
      return '0m';
    }
    return DateTimeUtils.formatSecondsAsMinutesLabel(s.durationSeconds);
  }

  String get startTimeLabel {
    final s = session.value;
    if (s == null) {
      return '—';
    }
    return DateTimeUtils.formatClockTime(
      DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
    );
  }

  String get endTimeLabel {
    final s = session.value;
    if (s == null) {
      return '—';
    }
    return DateTimeUtils.formatClockTime(
      DateTime.fromMillisecondsSinceEpoch(
        s.endedAtMs ?? s.startedAtMs,
        isUtc: true,
      ),
    );
  }

  int get goalContributionPercent {
    final s = session.value;
    final goal = dailyGoalMinutes.value;
    if (s == null || goal <= 0) {
      return 0;
    }
    final minutes = s.durationSeconds / 60.0;
    return ((minutes / goal) * 100).round().clamp(0, 100);
  }

  String get dailyProgressLabel =>
      '${DateTimeUtils.formatMinutes(todayStudiedMinutes.value)} of ${DateTimeUtils.formatMinutes(dailyGoalMinutes.value)}';

  double get dailyProgressFraction {
    final goal = dailyGoalMinutes.value;
    if (goal <= 0) {
      return 0;
    }
    return (todayStudiedMinutes.value / goal).clamp(0.0, 1.0);
  }

  Future<void> saveNotes(String rawNotes) async {
    final current = session.value;
    if (current == null || isSavingNotes.value) {
      return;
    }
    isSavingNotes.value = true;
    try {
      final clean = rawNotes.trim();
      final nextNotes = clean.isEmpty ? null : clean;
      await _sessionRepository.updateSessionNotes(current.id, nextNotes);
      final updated = StudySessionEntity(
        id: current.id,
        subjectId: current.subjectId,
        sessionType: current.sessionType,
        startedAtMs: current.startedAtMs,
        endedAtMs: current.endedAtMs,
        durationSeconds: current.durationSeconds,
        status: current.status,
        notes: nextNotes,
        createdAtMs: current.createdAtMs,
      );
      if (!_disposed) {
        session.value = updated;
        notesController.text = nextNotes ?? '';
      }
    } finally {
      if (!_disposed) {
        isSavingNotes.value = false;
      }
    }
  }

  void saveAndGoHome() {
    _timerEngine.lastCompletedSession.value = null;
    unawaited(Get.offAllNamed<void>(AppRoutes.home));
  }

  void startAnotherSession() {
    final currentSubjectId = session.value?.subjectId;
    final currentMode = session.value?.sessionType;
    _timerEngine.lastCompletedSession.value = null;
    unawaited(
      Get.offNamed<void>(
        AppRoutes.sessionSetup,
        arguments: <String, dynamic>{
          if (currentSubjectId != null) 'subjectId': currentSubjectId,
          if (currentMode != null) 'mode': currentMode,
        },
      ),
    );
  }

  @override
  void onClose() {
    _disposed = true;
    notesController.dispose();
    super.onClose();
  }
}
