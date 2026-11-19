import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subjects_table.dart';

part 'subject_dao.g.dart';

@DriftAccessor(tables: <Type>[Subjects])
class SubjectDao extends DatabaseAccessor<AppDatabase> with _$SubjectDaoMixin {
  SubjectDao(super.db);

  Stream<List<Subject>> watchAllSubjects({bool? archived}) {
    final query = select(subjects)
      ..orderBy(<OrderingTerm Function(Subjects)>[
        (t) => OrderingTerm.asc(t.name),
      ]);
    if (archived != null) {
      query.where((t) => t.isArchived.equals(archived));
    }
    return query.watch();
  }

  Future<List<Subject>> getAllSubjects({bool? archived}) {
    final query = select(subjects)
      ..orderBy(<OrderingTerm Function(Subjects)>[
        (t) => OrderingTerm.asc(t.name),
      ]);
    if (archived != null) {
      query.where((t) => t.isArchived.equals(archived));
    }
    return query.get();
  }

  Future<Subject?> getSubjectById(int id) {
    return (select(subjects)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Subject?> watchSubjectById(int id) {
    return (select(subjects)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<int> insertSubject(SubjectsCompanion entry) {
    return into(subjects).insert(entry);
  }

  Future<bool> updateSubject(SubjectsCompanion entry) {
    return (update(subjects)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<int> setArchived(int id, {required bool isArchived, required int nowMs}) {
    return (update(subjects)..where((t) => t.id.equals(id))).write(
      SubjectsCompanion(
        isArchived: Value<bool>(isArchived),
        updatedAt: Value<int>(nowMs),
      ),
    );
  }

  Future<int> deleteSubjectById(int id) {
    return (delete(subjects)..where((t) => t.id.equals(id))).go();
  }
}
