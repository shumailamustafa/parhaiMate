import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../domain/repositories/repositories.dart';

class SplashViewModel extends GetxController {
  SplashViewModel({
    required SettingsRepository settingsRepository,
    required TimerEngineService timerEngine,
    this.splashDelay = const Duration(milliseconds: 700),
  })  : _settingsRepository = settingsRepository,
        _timerEngine = timerEngine;

  final SettingsRepository _settingsRepository;
  final TimerEngineService _timerEngine;
  final Duration splashDelay;

  final RxInt activeDot = 0.obs;
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

  Future<void> _bootstrap() async {
    await _timerEngine.restoreOnLaunch();
    final onboardingDone = await _settingsRepository.isOnboardingCompleted();

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

    if (onboardingDone) {
      await Get.offAllNamed<void>(AppRoutes.home);
    } else {
      await Get.offAllNamed<void>(AppRoutes.onboarding);
    }
  }

  @override
  void onClose() {
    _dotTimer?.cancel();
    super.onClose();
  }
}
