import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/planner_tasks_table.dart';

part 'planner_dao.g.dart';

@DriftAccessor(tables: <Type>[PlannerTasks])
class PlannerDao extends DatabaseAccessor<AppDatabase> with _$PlannerDaoMixin {
  PlannerDao(super.db);

  Stream<List<PlannerTask>> watchTasksByDate(String dateKey) {
    return (select(plannerTasks)
          ..where((t) => t.scheduledDate.equals(dateKey))
          ..orderBy(<OrderingTerm Function(PlannerTasks)>[
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.scheduledTime),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<PlannerTask>> getTasksByDate(String dateKey) {
    return (select(plannerTasks)
          ..where((t) => t.scheduledDate.equals(dateKey))
          ..orderBy(<OrderingTerm Function(PlannerTasks)>[
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.scheduledTime),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Future<List<PlannerTask>> getAllTasks() {
    return (select(plannerTasks)
          ..orderBy(<OrderingTerm Function(PlannerTasks)>[
            (t) => OrderingTerm.asc(t.scheduledDate),
            (t) => OrderingTerm.asc(t.scheduledTime),
          ]))
        .get();
  }

  Stream<List<PlannerTask>> watchAllTasks() {
    return (select(plannerTasks)
          ..orderBy(<OrderingTerm Function(PlannerTasks)>[
            (t) => OrderingTerm.asc(t.scheduledDate),
            (t) => OrderingTerm.asc(t.scheduledTime),
          ]))
        .watch();
  }

  Future<PlannerTask?> getTaskById(int id) {
    return (select(plannerTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTask(PlannerTasksCompanion entry) {
    return into(plannerTasks).insert(entry);
  }

  Future<bool> updateTask(PlannerTasksCompanion entry) {
    return (update(plannerTasks)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<int> toggleTaskCompletion(
    int id, {
    required bool isCompleted,
    required int nowMs,
  }) {
    return (update(plannerTasks)..where((t) => t.id.equals(id))).write(
      PlannerTasksCompanion(
        isCompleted: Value<bool>(isCompleted),
        updatedAt: Value<int>(nowMs),
      ),
    );
  }

  Future<int> deleteTaskById(int id) {
    return (delete(plannerTasks)..where((t) => t.id.equals(id))).go();
  }
}
