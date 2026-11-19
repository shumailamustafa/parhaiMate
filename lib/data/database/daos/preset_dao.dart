import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/timer_presets_table.dart';

part 'preset_dao.g.dart';

@DriftAccessor(tables: <Type>[TimerPresets])
class PresetDao extends DatabaseAccessor<AppDatabase> with _$PresetDaoMixin {
  PresetDao(super.db);

  Stream<List<TimerPreset>> watchAllPresets() {
    return (select(timerPresets)
          ..orderBy(<OrderingTerm Function(TimerPresets)>[
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<List<TimerPreset>> getAllPresets() {
    return (select(timerPresets)
          ..orderBy(<OrderingTerm Function(TimerPresets)>[
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<TimerPreset?> getPresetById(int id) {
    return (select(timerPresets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertPreset(TimerPresetsCompanion entry) {
    return into(timerPresets).insert(entry);
  }

  Future<bool> updatePreset(TimerPresetsCompanion entry) {
    return (update(timerPresets)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<int> deletePresetById(int id) {
    return (delete(timerPresets)..where((t) => t.id.equals(id))).go();
  }
}
