import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Session Setup (05 Session Setup.png & variants).
class SessionSetupViewModel extends GetxController {
  SessionSetupViewModel({
    required SubjectRepository subjectRepository,
    required SettingsRepository settingsRepository,
    required TimerEngineService timerEngine,
    LocalNotificationService? notificationService,
    DateTime Function()? nowProvider,
    dynamic initialArgs,
  })  : _subjectRepository = subjectRepository,
        _settingsRepository = settingsRepository,
        _timerEngine = timerEngine,
        _notificationService = notificationService,
        _nowProvider = nowProvider ?? DateTime.now,
        _initialArgs = initialArgs;

  final LocalNotificationService? _notificationService;

  /// True once per install, before the first session, when Android has not
  /// yet granted notifications. The View then explains why before asking.
  Future<bool> shouldExplainNotifications() async {
    final service = _notificationService;
    if (service == null || !service.isInitialized || !service.isEnabled) {
      return false;
    }
    if (await _settingsRepository.wasNotificationPromptShown()) {
      return false;
    }
    return !(await service.areNotificationsAllowed());
  }

  Future<void> respondToNotificationExplanation({required bool allow}) async {
    await _settingsRepository.markNotificationPromptShown();
    if (allow) {
      await _notificationService?.requestPermission();
    }
  }
  static const List<int> durationChoices = <int>[15, 25, 30, 45, 60];

  final SubjectRepository _subjectRepository;
  final SettingsRepository _settingsRepository;
  final TimerEngineService _timerEngine;
  final DateTime Function() _nowProvider;
  final dynamic _initialArgs;

  final TextEditingController notesController = TextEditingController();

  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  final RxnInt selectedSubjectId = RxnInt();
  final Rx<TimerMode> selectedMode = TimerMode.focus.obs;
  final RxInt focusMinutes = 25.obs;
  final RxInt shortBreakMinutes = 5.obs;
  final RxInt longBreakMinutes = 15.obs;
  final RxInt totalCycles = 4.obs;
  final RxString notesText = ''.obs;
  final RxBool isStarting = false.obs;

  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  bool _modeExplicitlySet = false;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _applyInitialArguments(_initialArgs ?? Get.arguments);
    notesController.addListener(() {
      notesText.value = notesController.text;
    });
    _subjectsSub = _subjectRepository
        .watchSubjects(archived: false)
        .listen(subjects.assignAll);
    if (!_modeExplicitlySet) {
      unawaited(_loadDefaultMode());
    }
  }

  void _applyInitialArguments(dynamic args) {
    if (args is int) {
      selectedSubjectId.value = args;
      return;
    }
    if (args is Map<String, dynamic>) {
      final modeArg = args['mode'];
      if (modeArg is TimerMode) {
        selectedMode.value = modeArg;
        _modeExplicitlySet = true;
      }
      final subjectArg = args['subjectId'];
      if (subjectArg is int) {
        selectedSubjectId.value = subjectArg;
      }
      final focusArg = args['focusMinutes'];
      if (focusArg is int) {
        focusMinutes.value = focusArg.clamp(5, 180);
      }
      final shortArg = args['shortBreakMinutes'];
      if (shortArg is int) {
        shortBreakMinutes.value = shortArg.clamp(1, 30);
      }
      final longArg = args['longBreakMinutes'];
      if (longArg is int) {
        longBreakMinutes.value = longArg.clamp(5, 60);
      }
      final cyclesArg = args['totalCycles'];
      if (cyclesArg is int) {
        totalCycles.value = cyclesArg.clamp(1, 8);
      }
      final notesArg = args['notes'];
      if (notesArg is String && notesArg.trim().isNotEmpty) {
        notesController.text = notesArg.trim();
        notesText.value = notesController.text;
      }
    }
  }

  Future<void> _loadDefaultMode() async {
    final mode = await _settingsRepository.getDefaultTimerMode();
    if (!_disposed && !_modeExplicitlySet) {
      selectedMode.value = mode;
    }
  }

  void selectMode(TimerMode mode) {
    _modeExplicitlySet = true;
    selectedMode.value = mode;
  }

  void selectSubject(int? subjectId) {
    selectedSubjectId.value = subjectId;
  }

  void selectDuration(int minutes) {
    focusMinutes.value = minutes.clamp(5, 180);
  }

  void adjustFocusMinutes(int delta) {
    focusMinutes.value = (focusMinutes.value + delta).clamp(5, 180);
  }

  void adjustShortBreakMinutes(int delta) {
    shortBreakMinutes.value = (shortBreakMinutes.value + delta).clamp(1, 30);
  }

  void adjustLongBreakMinutes(int delta) {
    longBreakMinutes.value = (longBreakMinutes.value + delta).clamp(5, 60);
  }

  void adjustCycles(int delta) {
    totalCycles.value = (totalCycles.value + delta).clamp(1, 8);
  }

  bool isPresetDuration(int minutes) => durationChoices.contains(minutes);

  SubjectEntity? get selectedSubject {
    final id = selectedSubjectId.value;
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

  String get subjectSummaryLabel => selectedSubject?.name ?? 'General Study';

  String get modeSummaryLabel => selectedMode.value.label;

  int get totalPlannedMinutes {
    switch (selectedMode.value) {
      case TimerMode.focus:
        return focusMinutes.value;
      case TimerMode.stopwatch:
        return 0;
      case TimerMode.pomodoro:
        // N focus cycles, a short break between them, then one long break.
        return (totalCycles.value * focusMinutes.value) +
            (math.max(0, totalCycles.value - 1) * shortBreakMinutes.value) +
            longBreakMinutes.value;
    }
  }

  String get plannedTimeLabel {
    if (selectedMode.value == TimerMode.stopwatch) {
      return 'No time limit';
    }
    return DateTimeUtils.formatMinutes(totalPlannedMinutes);
  }

  String get endsAtLabel {
    if (selectedMode.value == TimerMode.stopwatch) {
      return '—';
    }
    final endAt = _nowProvider().add(Duration(minutes: totalPlannedMinutes));
    return DateTimeUtils.formatClockTime(endAt);
  }

  Future<void> startSession() async {
    if (isStarting.value) {
      return;
    }
    isStarting.value = true;
    try {
      final cleanNotes = notesText.value.trim();
      await _timerEngine.startSession(
        subjectId: selectedSubjectId.value,
        mode: selectedMode.value,
        focusMinutes: focusMinutes.value,
        shortBreakMinutes: shortBreakMinutes.value,
        longBreakMinutes: longBreakMinutes.value,
        totalCycles: totalCycles.value,
        notes: cleanNotes.isEmpty ? null : cleanNotes,
      );
      unawaited(Get.offNamed<void>(AppRoutes.activeFocus));
    } finally {
      if (!_disposed) {
        isStarting.value = false;
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    unawaited(_subjectsSub?.cancel());
    notesController.dispose();
    super.onClose();
  }
}
