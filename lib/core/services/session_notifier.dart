/// A local alert the timer engine wants delivered at an absolute UTC time.
class ScheduledAlert {
  const ScheduledAlert({
    required this.atMs,
    required this.title,
    required this.body,
  });

  /// UTC Unix milliseconds when the alert should fire.
  final int atMs;
  final String title;
  final String body;
}

/// Abstraction the timer engine uses to schedule phase/completion alerts.
///
/// Keeps the engine free of plugin code so it stays unit-testable.
abstract interface class SessionNotifier {
  /// Replaces any previously scheduled session alerts with [alerts].
  Future<void> scheduleSessionAlerts(List<ScheduledAlert> alerts);

  /// Removes every pending session alert.
  Future<void> cancelSessionAlerts();
}

/// Default notifier used in tests and when notifications are unavailable.
class NoopSessionNotifier implements SessionNotifier {
  const NoopSessionNotifier();

  @override
  Future<void> scheduleSessionAlerts(List<ScheduledAlert> alerts) async {}

  @override
  Future<void> cancelSessionAlerts() async {}
}
