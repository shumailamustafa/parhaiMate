import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Settings mode/goal/data management actions.
class SettingsViewModel extends GetxController {
  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required GoalStreakRepository goalStreakRepository,
    required PresetRepository presetRepository,
    required SessionRepository sessionRepository,
    required SubjectRepository subjectRepository,
    required TimerEngineService timerEngine,
    LocalNotificationService? notificationService,
  })  : _settingsRepo = settingsRepository,
        _goalRepo = goalStreakRepository,
        _presetRepo = presetRepository,
        _sessionRepo = sessionRepository,
        _subjectRepo = subjectRepository,
        _timerEngine = timerEngine,
        _notificationService = notificationService;

  final LocalNotificationService? _notificationService;
  final RxBool sessionAlertsEnabled = true.obs;

  /// False when Android itself blocks this app's notifications.
  final RxBool systemNotificationsAllowed = true.obs;

  bool get notificationsBlocked =>
      (_notificationService?.isInitialized ?? false) &&
      sessionAlertsEnabled.value &&
      !systemNotificationsAllowed.value;

  Future<void> requestNotificationPermission() async {
    await _notificationService?.requestPermission();
    await _refreshNotificationAccess();
    await _timerEngine.rescheduleAlerts();
  }

  Future<void> _refreshNotificationAccess() async {
    final service = _notificationService;
    final realDevice = service != null && service.isInitialized;
    final posted = !realDevice || await service.areNotificationsAllowed();
    if (!_disposed) {
      systemNotificationsAllowed.value = posted;
    }
  }

  Future<void> setSessionAlertsEnabled({required bool enabled}) async {
    await _settingsRepo.setSessionAlertsEnabled(enabled: enabled);
    _notificationService?.setEnabled(enabled: enabled);
    if (enabled) {
      await _notificationService?.requestPermission();
      await _refreshNotificationAccess();
      await _timerEngine.rescheduleAlerts();
    } else {
      await _notificationService?.cancelSessionAlerts();
    }
    if (!_disposed) {
      sessionAlertsEnabled.value = enabled;
    }
  }

  final SettingsRepository _settingsRepo;
  final GoalStreakRepository _goalRepo;
  final PresetRepository _presetRepo;
  final SessionRepository _sessionRepo;
  final SubjectRepository _subjectRepo;
  final TimerEngineService _timerEngine;

  final RxInt dailyGoalMinutes = 240.obs;
  final RxInt weeklyGoalMinutes = 1200.obs;
  final Rx<TimerMode> defaultTimerMode = TimerMode.pomodoro.obs;
  final RxInt presetsCount = 3.obs;
  final RxInt sessionsCount = 0.obs;
  final RxInt subjectsCount = 0.obs;
  final RxBool isProcessingData = false.obs;

  StreamSubscription<List<TimerPresetEntity>>? _presetsSub;
  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _presetsSub = _presetRepo.watchPresets().listen((list) {
      presetsCount.value = list.length;
    });
    _sessionsSub = _sessionRepo.watchCompletedSessions().listen((list) {
      sessionsCount.value = list.length;
    });
    _subjectsSub = _subjectRepo.watchSubjects().listen((list) {
      subjectsCount.value = list.length;
    });
    unawaited(refreshSettings());
  }

  Future<void> refreshSettings() async {
    final daily = await _goalRepo.getDailyGoalMinutes();
    final weekly = await _goalRepo.getWeeklyGoalMinutes();
    final mode = await _settingsRepo.getDefaultTimerMode();
    final alerts = await _settingsRepo.areSessionAlertsEnabled();
    if (!_disposed) {
      dailyGoalMinutes.value = daily;
      weeklyGoalMinutes.value = weekly;
      defaultTimerMode.value = mode;
      sessionAlertsEnabled.value = alerts;
    }
    await _refreshNotificationAccess();
  }

  Future<void> setDefaultTimerMode(TimerMode mode) async {
    await _settingsRepo.setDefaultTimerMode(mode);
    if (!_disposed) {
      defaultTimerMode.value = mode;
    }
  }

  Future<void> clearStudyHistory() async {
    if (isProcessingData.value) {
      return;
    }
    isProcessingData.value = true;
    try {
      // Stop the live timer first; otherwise it keeps running in memory and
      // later tries to complete a session row that no longer exists.
      if (_timerEngine.hasActiveSession) {
        await _timerEngine.cancelSession();
      }
      await _sessionRepo.clearHistory();
    } finally {
      if (!_disposed) {
        isProcessingData.value = false;
      }
    }
  }

  Future<void> deleteAllAppData() async {
    if (isProcessingData.value) {
      return;
    }
    isProcessingData.value = true;
    try {
      if (_timerEngine.hasActiveSession) {
        await _timerEngine.cancelSession();
      }
      await _settingsRepo.resetAllAppData();
      await _settingsRepo.setOnboardingCompleted(completed: true);
      await refreshSettings();
      unawaited(Get.offAllNamed<void>(AppRoutes.home));
    } finally {
      if (!_disposed) {
        isProcessingData.value = false;
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    unawaited(_presetsSub?.cancel());
    unawaited(_sessionsSub?.cancel());
    unawaited(_subjectsSub?.cancel());
    super.onClose();
  }
}
