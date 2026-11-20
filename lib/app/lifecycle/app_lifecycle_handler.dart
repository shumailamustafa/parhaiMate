import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/services/timer_engine_service.dart';

/// Pauses the on-screen timer ticker in the background and reconciles
/// persisted timer timestamps whenever the app becomes visible again.
class AppLifecycleHandler with WidgetsBindingObserver {
  AppLifecycleHandler(this._timerEngine);

  final TimerEngineService _timerEngine;
  bool _registered = false;

  void attach() {
    if (_registered) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _registered = true;
  }

  void detach() {
    if (!_registered) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _registered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_timerEngine.onAppForegrounded());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _timerEngine.onAppBackgrounded();
      case AppLifecycleState.inactive:
        // Brief interruptions (notification shade, dialogs): keep ticking.
        break;
    }
  }
}
