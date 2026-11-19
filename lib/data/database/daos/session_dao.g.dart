// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $StudySessionsTable get studySessions => attachedDatabase.studySessions;
  $SessionEventsTable get sessionEvents => attachedDatabase.sessionEvents;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db.attachedDatabase, _db.studySessions);
  $$SessionEventsTableTableManager get sessionEvents =>
      $$SessionEventsTableTableManager(_db.attachedDatabase, _db.sessionEvents);
}
