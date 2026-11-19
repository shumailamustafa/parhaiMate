import 'package:get/get.dart';

import '../../../core/services/timer_engine_service.dart';

class MainShellViewModel extends GetxController {
  MainShellViewModel({
    required this.timerEngine,
    int initialTab = 0,
  }) : currentIndex = initialTab.obs;

  final TimerEngineService timerEngine;
  final RxInt currentIndex;

  void changeTab(int index) {
    if (index < 0 || index > 3) {
      return;
    }
    currentIndex.value = index;
  }
}
