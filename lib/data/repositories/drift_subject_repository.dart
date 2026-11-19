import 'package:drift/drift.dart';

import '../../domain/entities/domain_entities.dart';
import '../../domain/enums/domain_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';
import '../models/data_mappers.dart';

class DriftSubjectRepository implements SubjectRepository {
  DriftSubjectRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<SubjectEntity>> watchSubjects({bool? archived}) {
    return _db.subjectDao
        .watchAllSubjects(archived: archived)
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<List<SubjectEntity>> getSubjects({bool? archived}) async {
    final rows = await _db.subjectDao.getAllSubjects(archived: archived);
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<SubjectEntity?> getById(int id) async {
    final row = await _db.subjectDao.getSubjectById(id);
    return row?.toEntity();
  }

  @override
  Stream<SubjectEntity?> watchById(int id) {
    return _db.subjectDao.watchSubjectById(id).map((row) => row?.toEntity());
  }

  @override
  Future<int> createSubject({
    required String name,
    required SubjectIdentifier identifier,
    required SubjectIconKey iconKey,
    required int targetMinutes,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return _db.subjectDao.insertSubject(
      SubjectsCompanion.insert(
        name: name.trim(),
        color: Value<String>(identifier.key),
        icon: Value<String>(iconKey.key),
        targetMinutes: Value<int>(targetMinutes),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateSubject(SubjectEntity subject) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.subjectDao.updateSubject(
      SubjectsCompanion(
        id: Value<int>(subject.id),
        name: Value<String>(subject.name.trim()),
        color: Value<String>(subject.identifier.key),
        icon: Value<String>(subject.iconKey.key),
        targetMinutes: Value<int>(subject.targetMinutes),
        updatedAt: Value<int>(now),
        isArchived: Value<bool>(subject.isArchived),
      ),
    );
  }

  @override
  Future<void> setArchived(int id, {required bool isArchived}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.subjectDao.setArchived(id, isArchived: isArchived, nowMs: now);
  }

  @override
  Future<void> deleteSubject(int id) async {
    await _db.subjectDao.deleteSubjectById(id);
  }
}
