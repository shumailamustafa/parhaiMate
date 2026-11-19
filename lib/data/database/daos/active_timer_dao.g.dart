// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_timer_dao.dart';

// ignore_for_file: type=lint
mixin _$ActiveTimerDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $StudySessionsTable get studySessions => attachedDatabase.studySessions;
  $ActiveTimerStatesTable get activeTimerStates =>
      attachedDatabase.activeTimerStates;
  ActiveTimerDaoManager get managers => ActiveTimerDaoManager(this);
}

class ActiveTimerDaoManager {
  final _$ActiveTimerDaoMixin _db;
  ActiveTimerDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db.attachedDatabase, _db.studySessions);
  $$ActiveTimerStatesTableTableManager get activeTimerStates =>
      $$ActiveTimerStatesTableTableManager(
        _db.attachedDatabase,
        _db.activeTimerStates,
      );
}
