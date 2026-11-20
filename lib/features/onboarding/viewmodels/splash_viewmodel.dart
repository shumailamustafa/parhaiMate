import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../domain/repositories/repositories.dart';

class SplashViewModel extends GetxController {
  SplashViewModel({
    required SettingsRepository settingsRepository,
    required TimerEngineService timerEngine,
    LocalNotificationService? notificationService,
    this.splashDelay = const Duration(milliseconds: 700),
  })  : _settingsRepository = settingsRepository,
        _timerEngine = timerEngine,
        _notificationService = notificationService;

  final SettingsRepository _settingsRepository;
  final TimerEngineService _timerEngine;
  final LocalNotificationService? _notificationService;
  final Duration splashDelay;

  final RxInt activeDot = 0.obs;

  /// Set when startup fails (for example the database cannot be opened).
  final RxnString errorMessage = RxnString();
  Timer? _dotTimer;
  bool _navigated = false;

  @override
  void onInit() {
    super.onInit();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      activeDot.value = (activeDot.value + 1) % 3;
    });
    unawaited(_bootstrap());
  }

  Future<void> retry() async {
    errorMessage.value = null;
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bool onboardingDone;
    try {
      _notificationService?.setEnabled(
        enabled: await _settingsRepository.areSessionAlertsEnabled(),
      );
      await _timerEngine.restoreOnLaunch();
      onboardingDone = await _settingsRepository.isOnboardingCompleted();
    } catch (error) {
      debugPrint('Startup failed: $error');
      if (!isClosed) {
        errorMessage.value =
            "ParhaiMate couldn't open your study data. Please try again.";
      }
      return;
    }

    if (splashDelay > Duration.zero) {
      await Future<void>.delayed(splashDelay);
    }

    if (_navigated || isClosed) {
      return;
    }
    _navigated = true;

    if (_timerEngine.hasActiveSession) {
      await Get.offAllNamed<void>(AppRoutes.activeFocus);
      return;
    }

    if (!onboardingDone) {
      await Get.offAllNamed<void>(AppRoutes.onboarding);
      return;
    }

    // A timer that finished while the app was closed was saved during
    // restore; show its summary instead of silently dropping the user on Home.
    final finished = _timerEngine.lastCompletedSession.value;
    unawaited(Get.offAllNamed<void>(AppRoutes.home));
    if (finished != null) {
      unawaited(
        Get.toNamed<void>(AppRoutes.sessionSummary, arguments: finished.id),
      );
    }
  }

  @override
  void onClose() {
    _dotTimer?.cancel();
    super.onClose();
  }
}
