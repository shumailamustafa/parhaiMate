import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/timer_engine_service.dart';
import '../../../domain/entities/domain_entities.dart';

class MainShellViewModel extends GetxController {
  MainShellViewModel({
    required this.timerEngine,
    int initialTab = 0,
  }) : currentIndex = initialTab.obs;

  final TimerEngineService timerEngine;
  final RxInt currentIndex;
  Worker? _completionWorker;

  @override
  void onInit() {
    super.onInit();
    // A minimized session can finish while the user is on the tabs (the
    // engine reconciles on resume). Show its summary instead of losing it.
    // Active Focus handles this itself when it is the visible screen.
    _completionWorker = ever<StudySessionEntity?>(
      timerEngine.lastCompletedSession,
      (session) {
        if (session != null && Get.currentRoute == AppRoutes.home) {
          unawaited(
            Get.toNamed<void>(AppRoutes.sessionSummary, arguments: session.id),
          );
        }
      },
    );
  }

  void changeTab(int index) {
    if (index < 0 || index > 3) {
      return;
    }
    currentIndex.value = index;
  }

  @override
  void onClose() {
    _completionWorker?.dispose();
    super.onClose();
  }
}
