import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'session_notifier.dart';

/// Schedules local session alerts with inexact Android alarms.
///
/// No exact-alarm permission, foreground service, or full-screen intent is
/// used. Alerts are scheduled against absolute UTC instants, so device
/// timezone changes do not shift them. Every plugin call is guarded: a
/// notification failure must never break the timer itself.
class LocalNotificationService implements SessionNotifier {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'study_sessions';
  static const String _channelName = 'Study session alerts';
  static const String _channelDescription =
      'Tells you when a focus phase, break, or study session ends.';

  /// Session alerts use a fixed ID range so they can be cancelled together.
  static const int _firstAlertId = 7000;
  static const int _maxAlerts = 40;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _enabled = true;

  bool get isEnabled => _enabled;

  /// False in tests and whenever the plugin failed to start.
  bool get isInitialized => _initialized;

  Future<void> initialize({required bool enabled}) async {
    _enabled = enabled;
    if (_initialized) {
      return;
    }
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _initialized = true;
    } catch (error) {
      debugPrint('Notifications unavailable: $error');
    }
  }

  void setEnabled({required bool enabled}) {
    _enabled = enabled;
  }

  /// Whether Android currently allows this app to post notifications.
  Future<bool> areNotificationsAllowed() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the Android 13+ runtime permission prompt.
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> scheduleSessionAlerts(List<ScheduledAlert> alerts) async {
    await cancelSessionAlerts();
    if (!_initialized || !_enabled) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    );
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    var index = 0;
    for (final alert in alerts) {
      if (index >= _maxAlerts) {
        break;
      }
      if (alert.atMs <= nowMs) {
        continue;
      }
      try {
        await _plugin.zonedSchedule(
          id: _firstAlertId + index,
          scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(
            tz.UTC,
            alert.atMs,
          ),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: alert.title,
          body: alert.body,
        );
        index += 1;
      } catch (error) {
        debugPrint('Could not schedule session alert: $error');
        return;
      }
    }
  }

  @override
  Future<void> cancelSessionAlerts() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxAlerts; i++) {
      try {
        await _plugin.cancel(id: _firstAlertId + i);
      } catch (_) {
        return;
      }
    }
  }
}
