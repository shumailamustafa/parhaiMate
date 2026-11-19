import 'package:drift/drift.dart';

import '../../domain/entities/domain_entities.dart';
import '../../domain/enums/domain_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';
import '../models/data_mappers.dart';

class DriftPresetRepository implements PresetRepository {
  DriftPresetRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<TimerPresetEntity>> watchPresets() {
    return _db.presetDao
        .watchAllPresets()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<List<TimerPresetEntity>> getPresets() async {
    final rows = await _db.presetDao.getAllPresets();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<TimerPresetEntity?> getById(int id) async {
    final row = await _db.presetDao.getPresetById(id);
    return row?.toEntity();
  }

  @override
  Future<int> createPreset({
    required String name,
    required TimerMode timerMode,
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int cyclesBeforeLongBreak,
  }) {
    return _db.presetDao.insertPreset(
      TimerPresetsCompanion.insert(
        name: name.trim(),
        timerMode: Value<String>(timerMode.key),
        focusMinutes: focusMinutes,
        shortBreakMinutes: shortBreakMinutes,
        longBreakMinutes: longBreakMinutes,
        cyclesBeforeLongBreak: cyclesBeforeLongBreak,
      ),
    );
  }

  @override
  Future<void> updatePreset(TimerPresetEntity preset) async {
    await _db.presetDao.updatePreset(
      TimerPresetsCompanion(
        id: Value<int>(preset.id),
        name: Value<String>(preset.name.trim()),
        timerMode: Value<String>(preset.timerMode.key),
        focusMinutes: Value<int>(preset.focusMinutes),
        shortBreakMinutes: Value<int>(preset.shortBreakMinutes),
        longBreakMinutes: Value<int>(preset.longBreakMinutes),
        cyclesBeforeLongBreak: Value<int>(preset.cyclesBeforeLongBreak),
        isDefault: Value<bool>(preset.isDefault),
      ),
    );
  }

  @override
  Future<void> deletePreset(int id) async {
    await _db.presetDao.deletePresetById(id);
  }
}
