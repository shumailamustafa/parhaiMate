import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/session_events_table.dart';
import '../tables/study_sessions_table.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: <Type>[StudySessions, SessionEvents])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Stream<List<StudySession>> watchCompletedSessions({int? subjectId}) {
    final query = select(studySessions)
      ..where((t) => t.status.equals('completed'))
      ..orderBy(<OrderingTerm Function(StudySessions)>[
        (t) => OrderingTerm.desc(t.startedAt),
      ]);
    if (subjectId != null) {
      query.where((t) => t.subjectId.equals(subjectId));
    }
    return query.watch();
  }

  Future<List<StudySession>> getCompletedSessions({
    int? subjectId,
    int? startMsInclusive,
    int? endMsExclusive,
  }) {
    final query = select(studySessions)
      ..where((t) => t.status.equals('completed'))
      ..orderBy(<OrderingTerm Function(StudySessions)>[
        (t) => OrderingTerm.desc(t.startedAt),
      ]);
    if (subjectId != null) {
      query.where((t) => t.subjectId.equals(subjectId));
    }
    if (startMsInclusive != null) {
      query.where((t) => t.startedAt.isBiggerOrEqualValue(startMsInclusive));
    }
    if (endMsExclusive != null) {
      query.where((t) => t.startedAt.isSmallerThanValue(endMsExclusive));
    }
    return query.get();
  }

  Future<StudySession?> getSessionById(int id) {
    return (select(studySessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertSession(StudySessionsCompanion entry) {
    return into(studySessions).insert(entry);
  }

  Future<int> updateSessionById(int id, StudySessionsCompanion entry) {
    return (update(studySessions)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> updateSessionNotes(int id, String? notes) {
    return (update(studySessions)..where((t) => t.id.equals(id)))
        .write(StudySessionsCompanion(notes: Value<String?>(notes)));
  }

  Future<int> insertSessionEvent(SessionEventsCompanion entry) {
    return into(sessionEvents).insert(entry);
  }

  Future<List<SessionEvent>> getEventsForSession(int sessionId) {
    return (select(sessionEvents)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy(<OrderingTerm Function(SessionEvents)>[
            (t) => OrderingTerm.asc(t.startedAt),
          ]))
        .get();
  }

  Future<int> clearAllSessions() async {
    await delete(sessionEvents).go();
    return delete(studySessions).go();
  }
}
