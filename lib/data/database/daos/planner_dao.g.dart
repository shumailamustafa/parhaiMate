// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_dao.dart';

// ignore_for_file: type=lint
mixin _$PlannerDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $PlannerTasksTable get plannerTasks => attachedDatabase.plannerTasks;
  PlannerDaoManager get managers => PlannerDaoManager(this);
}

class PlannerDaoManager {
  final _$PlannerDaoMixin _db;
  PlannerDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$PlannerTasksTableTableManager get plannerTasks =>
      $$PlannerTasksTableTableManager(_db.attachedDatabase, _db.plannerTasks);
}
