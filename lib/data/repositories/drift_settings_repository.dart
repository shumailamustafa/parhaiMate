import '../../domain/enums/domain_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<bool> isOnboardingCompleted() async {
    final raw =
        await _db.settingsDao.getValue(AppDatabase.keyOnboardingCompleted);
    return raw == 'true';
  }

  @override
  Future<void> setOnboardingCompleted({required bool completed}) {
    return _db.settingsDao.setValue(
      AppDatabase.keyOnboardingCompleted,
      completed ? 'true' : 'false',
    );
  }

  @override
  Future<TimerMode> getDefaultTimerMode() async {
    final raw = await _db.settingsDao.getValue(AppDatabase.keyDefaultTimerMode);
    return TimerMode.fromKey(raw);
  }

  @override
  Future<void> setDefaultTimerMode(TimerMode mode) {
    return _db.settingsDao.setValue(AppDatabase.keyDefaultTimerMode, mode.key);
  }

  @override
  Future<bool> areSessionAlertsEnabled() async {
    final raw =
        await _db.settingsDao.getValue(AppDatabase.keySessionAlertsEnabled);
    // Enabled unless the user explicitly turned alerts off.
    return raw != 'false';
  }

  @override
  Future<void> setSessionAlertsEnabled({required bool enabled}) {
    return _db.settingsDao.setValue(
      AppDatabase.keySessionAlertsEnabled,
      enabled ? 'true' : 'false',
    );
  }

  @override
  Future<bool> wasNotificationPromptShown() async {
    final raw =
        await _db.settingsDao.getValue(AppDatabase.keyNotificationPromptShown);
    return raw == 'true';
  }

  @override
  Future<void> markNotificationPromptShown() {
    return _db.settingsDao
        .setValue(AppDatabase.keyNotificationPromptShown, 'true');
  }

  @override
  Future<void> resetAllAppData() {
    return _db.resetAllUserData();
  }
}
