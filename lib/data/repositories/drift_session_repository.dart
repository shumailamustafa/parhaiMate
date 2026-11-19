import 'package:drift/drift.dart';

import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/domain_entities.dart';
import '../../domain/enums/domain_enums.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';
import '../models/data_mappers.dart';

class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db, this._achievementRepository);

  final AppDatabase _db;
  final AchievementRepository _achievementRepository;

  @override
  Stream<List<StudySessionEntity>> watchCompletedSessions({int? subjectId}) {
    return _db.sessionDao
        .watchCompletedSessions(subjectId: subjectId)
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<List<StudySessionEntity>> getCompletedSessions({
    int? subjectId,
    int? startMsInclusive,
    int? endMsExclusive,
  }) async {
    final rows = await _db.sessionDao.getCompletedSessions(
      subjectId: subjectId,
      startMsInclusive: startMsInclusive,
      endMsExclusive: endMsExclusive,
    );
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<StudySessionEntity?> getById(int id) async {
    final row = await _db.sessionDao.getSessionById(id);
    return row?.toEntity();
  }

  @override
  Future<int> createActiveSession({
    required int? subjectId,
    required TimerMode mode,
    required int startedAtMs,
    String? notes,
  }) {
    return _db.transaction(() async {
      final sessionId = await _db.sessionDao.insertSession(
        StudySessionsCompanion.insert(
          subjectId: Value<int?>(subjectId),
          sessionType: mode.key,
          startedAt: startedAtMs,
          durationSeconds: const Value<int>(0),
          status: SessionStatus.active.key,
          notes: Value<String?>(notes),
          createdAt: startedAtMs,
        ),
      );
      await _db.sessionDao.insertSessionEvent(
        SessionEventsCompanion.insert(
          sessionId: sessionId,
          eventType: 'start',
          startedAt: startedAtMs,
          endedAt: startedAtMs,
          durationSeconds: 0,
        ),
      );
      return sessionId;
    });
  }

  @override
  Future<void> recordSessionEvent({
    required int sessionId,
    required String eventType,
    required int startedAtMs,
    required int endedAtMs,
    required int durationSeconds,
  }) {
    return _db.sessionDao.insertSessionEvent(
      SessionEventsCompanion.insert(
        sessionId: sessionId,
        eventType: eventType,
        startedAt: startedAtMs,
        endedAt: endedAtMs,
        durationSeconds: durationSeconds,
      ),
    );
  }

  @override
  Future<StudySessionEntity> completeSession({
    required int sessionId,
    required int endedAtMs,
    required int durationSeconds,
    String? notes,
  }) {
    return _db.transaction(() async {
      final existing = await _db.sessionDao.getSessionById(sessionId);
      if (existing == null) {
        throw StateError('Session $sessionId not found');
      }
      // Idempotency guard: never save completion, streak minutes, or events twice.
      if (existing.status == SessionStatus.completed.key) {
        return existing.toEntity();
      }

      final safeDuration = durationSeconds < 0 ? 0 : durationSeconds;
      await _db.sessionDao.updateSessionById(
        sessionId,
        StudySessionsCompanion(
          status: Value<String>(SessionStatus.completed.key),
          endedAt: Value<int?>(endedAtMs),
          durationSeconds: Value<int>(safeDuration),
          notes: notes != null ? Value<String?>(notes) : const Value.absent(),
        ),
      );

      await _db.sessionDao.insertSessionEvent(
        SessionEventsCompanion.insert(
          sessionId: sessionId,
          eventType: 'complete',
          startedAt: existing.startedAt,
          endedAt: endedAtMs,
          durationSeconds: safeDuration,
        ),
      );

      final dateKey = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(existing.startedAt, isUtc: true),
      );
      final addedMinutes = safeDuration ~/ 60;
      await _db.goalStreakDao.addStudyMinutesForDate(
        dateKey: dateKey,
        addedMinutes: addedMinutes,
      );
      if (safeDuration > 0 && addedMinutes == 0) {
        final existingRecord =
            await _db.goalStreakDao.getStreakRecordForDate(dateKey);
        if (existingRecord != null && !existingRecord.streakQualified) {
          await _db.goalStreakDao.upsertStreakRecord(
            StreakRecordsCompanion(
              id: Value<int>(existingRecord.id),
              dateKey: Value<String>(dateKey),
              studyMinutes: Value<int>(existingRecord.studyMinutes),
              streakQualified: const Value<bool>(true),
            ),
          );
        }
      }

      await _db.activeTimerDao.clearActiveState();
      await _achievementRepository.evaluateAndUnlock(nowMs: endedAtMs);

      final updated = await _db.sessionDao.getSessionById(sessionId);
      return updated!.toEntity();
    });
  }

  @override
  Future<void> cancelSession({
    required int sessionId,
    required int cancelledAtMs,
  }) async {
    await _db.transaction(() async {
      final existing = await _db.sessionDao.getSessionById(sessionId);
      if (existing != null && existing.status == SessionStatus.active.key) {
        await _db.sessionDao.updateSessionById(
          sessionId,
          StudySessionsCompanion(
            status: Value<String>(SessionStatus.cancelled.key),
            endedAt: Value<int?>(cancelledAtMs),
          ),
        );
        await _db.sessionDao.insertSessionEvent(
          SessionEventsCompanion.insert(
            sessionId: sessionId,
            eventType: 'cancel',
            startedAt: existing.startedAt,
            endedAt: cancelledAtMs,
            durationSeconds: 0,
          ),
        );
      }
      await _db.activeTimerDao.clearActiveState();
    });
  }

  @override
  Future<void> updateSessionNotes(int sessionId, String? notes) async {
    await _db.sessionDao.updateSessionNotes(sessionId, notes);
  }

  @override
  Future<void> clearHistory() async {
    await _db.transaction(() async {
      await _db.activeTimerDao.clearActiveState();
      await _db.sessionDao.clearAllSessions();
      await _db.goalStreakDao.clearStreakRecords();
      await _db.achievementDao.resetAllUnlocks();
    });
  }
}
