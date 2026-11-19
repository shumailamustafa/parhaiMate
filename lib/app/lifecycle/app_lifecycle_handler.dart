import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/services/timer_engine_service.dart';

/// Reconciles persisted timer timestamps whenever the app resumes from background.
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
    if (state == AppLifecycleState.resumed) {
      unawaited(_timerEngine.reconcile());
    }
  }
}
