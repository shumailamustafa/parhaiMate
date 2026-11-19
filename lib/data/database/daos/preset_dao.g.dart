// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_dao.dart';

// ignore_for_file: type=lint
mixin _$PresetDaoMixin on DatabaseAccessor<AppDatabase> {
  $TimerPresetsTable get timerPresets => attachedDatabase.timerPresets;
  PresetDaoManager get managers => PresetDaoManager(this);
}

class PresetDaoManager {
  final _$PresetDaoMixin _db;
  PresetDaoManager(this._db);
  $$TimerPresetsTableTableManager get timerPresets =>
      $$TimerPresetsTableTableManager(_db.attachedDatabase, _db.timerPresets);
}
