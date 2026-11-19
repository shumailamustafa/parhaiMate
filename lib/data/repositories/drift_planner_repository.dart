import 'package:drift/drift.dart';

import '../../domain/entities/domain_entities.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';
import '../models/data_mappers.dart';

class DriftPlannerRepository implements PlannerRepository {
  DriftPlannerRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<PlannerTaskEntity>> watchTasksForDate(String dateKey) {
    return _db.plannerDao
        .watchTasksByDate(dateKey)
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Stream<List<PlannerTaskEntity>> watchAllTasks() {
    return _db.plannerDao
        .watchAllTasks()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<List<PlannerTaskEntity>> getTasksForDate(String dateKey) async {
    final rows = await _db.plannerDao.getTasksByDate(dateKey);
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<List<PlannerTaskEntity>> getAllTasks() async {
    final rows = await _db.plannerDao.getAllTasks();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<PlannerTaskEntity?> getById(int id) async {
    final row = await _db.plannerDao.getTaskById(id);
    return row?.toEntity();
  }

  @override
  Future<int> createTask({
    required int? subjectId,
    required String title,
    required String scheduledDate,
    String? scheduledTime,
    required int targetMinutes,
    String? notes,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return _db.plannerDao.insertTask(
      PlannerTasksCompanion.insert(
        subjectId: Value<int?>(subjectId),
        title: title.trim(),
        scheduledDate: scheduledDate,
        scheduledTime: Value<String?>(scheduledTime),
        targetMinutes: Value<int>(targetMinutes),
        notes: Value<String?>(notes?.trim().isEmpty == true ? null : notes?.trim()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateTask(PlannerTaskEntity task) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.plannerDao.updateTask(
      PlannerTasksCompanion(
        id: Value<int>(task.id),
        subjectId: Value<int?>(task.subjectId),
        title: Value<String>(task.title.trim()),
        scheduledDate: Value<String>(task.scheduledDate),
        scheduledTime: Value<String?>(task.scheduledTime),
        targetMinutes: Value<int>(task.targetMinutes),
        notes: Value<String?>(
          task.notes?.trim().isEmpty == true ? null : task.notes?.trim(),
        ),
        isCompleted: Value<bool>(task.isCompleted),
        updatedAt: Value<int>(now),
      ),
    );
  }

  @override
  Future<void> toggleTaskCompletion(int id, {required bool isCompleted}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.plannerDao.toggleTaskCompletion(
      id,
      isCompleted: isCompleted,
      nowMs: now,
    );
  }

  @override
  Future<void> deleteTask(int id) async {
    await _db.plannerDao.deleteTaskById(id);
  }
}
