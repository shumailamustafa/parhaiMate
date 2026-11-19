import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parhaimate/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Stage 3 Drift SQLite Database & DAOs', () {
    test('seeds default settings, presets, achievements, and enables foreign keys',
        () async {
      final fkResult = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(fkResult.data['foreign_keys'], 1);

      final settings = await db.settingsDao.getAllSettings();
      expect(settings[AppDatabase.keyDailyGoalMinutes], '240');
      expect(settings[AppDatabase.keyWeeklyGoalMinutes], '1200');
      expect(settings[AppDatabase.keyDefaultTimerMode], 'pomodoro');
      expect(settings[AppDatabase.keyOnboardingCompleted], 'false');

      final presets = await db.presetDao.getAllPresets();
      expect(presets.length, 3);
      expect(presets.first.name, 'Classic Pomodoro');

      final achievements = await db.achievementDao.getAllAchievements();
      expect(achievements.length, 6);
      expect(achievements.every((a) => a.unlockedAt == null), isTrue);
    });

    test('subject CRUD, archive/restore, and cascade delete work correctly',
        () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final subjectId = await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(
          name: 'Mathematics',
          color: const Value<String>('circle'),
          icon: const Value<String>('sigma'),
          targetMinutes: const Value<int>(300),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final activeList = await db.subjectDao.getAllSubjects(archived: false);
      expect(activeList.length, 1);
      expect(activeList.first.name, 'Mathematics');

      await db.subjectDao.setArchived(subjectId, isArchived: true, nowMs: now + 1);
      expect((await db.subjectDao.getAllSubjects(archived: false)).isEmpty, isTrue);
      expect((await db.subjectDao.getAllSubjects(archived: true)).length, 1);

      // Add linked session and planner task, then delete subject and check cascade.
      final sessionId = await db.sessionDao.insertSession(
        StudySessionsCompanion.insert(
          subjectId: Value<int?>(subjectId),
          sessionType: 'focus',
          startedAt: now,
          endedAt: Value<int?>(now + 1500000),
          durationSeconds: const Value<int>(1500),
          status: 'completed',
          createdAt: now,
        ),
      );
      await db.sessionDao.insertSessionEvent(
        SessionEventsCompanion.insert(
          sessionId: sessionId,
          eventType: 'complete',
          startedAt: now,
          endedAt: now + 1500000,
          durationSeconds: 1500,
        ),
      );
      await db.plannerDao.insertTask(
        PlannerTasksCompanion.insert(
          subjectId: Value<int?>(subjectId),
          title: 'Revise integration',
          scheduledDate: '2026-05-12',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.subjectDao.deleteSubjectById(subjectId);
      expect(await db.sessionDao.getSessionById(sessionId), isNull);
      expect(await db.sessionDao.getEventsForSession(sessionId), isEmpty);
      expect(await db.plannerDao.getAllTasks(), isEmpty);
    });

    test('supports unassigned sessions (nullable subjectId) and notes',
        () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final sessionId = await db.sessionDao.insertSession(
        StudySessionsCompanion.insert(
          subjectId: const Value<int?>(null),
          sessionType: 'stopwatch',
          startedAt: now,
          endedAt: Value<int?>(now + 600000),
          durationSeconds: const Value<int>(600),
          status: 'completed',
          createdAt: now,
        ),
      );

      await db.sessionDao.updateSessionNotes(sessionId, 'General revision');
      final fetched = await db.sessionDao.getSessionById(sessionId);
      expect(fetched, isNotNull);
      expect(fetched!.subjectId, isNull);
      expect(fetched.notes, 'General revision');
    });

    test('goals, streaks, achievements, and single-row active timer persist',
        () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.goalStreakDao.upsertDailyGoal(
        dateKey: '2026-05-12',
        targetMinutes: 240,
        nowMs: now,
      );
      final goal = await db.goalStreakDao.getGoalForDate('2026-05-12');
      expect(goal?.targetMinutes, 240);

      await db.goalStreakDao.addStudyMinutesForDate(
        dateKey: '2026-05-12',
        addedMinutes: 55,
      );
      final streak = await db.goalStreakDao.getStreakRecordForDate('2026-05-12');
      expect(streak?.studyMinutes, 55);
      expect(streak?.streakQualified, isTrue);

      await db.achievementDao.unlockAchievement('first_session', now);
      final unlocked = await db.achievementDao.getByCode('first_session');
      expect(unlocked?.unlockedAt, now);

      await db.activeTimerDao.saveActiveState(
        ActiveTimerStatesCompanion.insert(
          id: const Value<int>(1),
          timerMode: 'focus',
          phase: 'focusing',
          targetEndAt: Value<int?>(now + 1500000),
          plannedDurationSeconds: const Value<int>(1500),
          updatedAt: now,
        ),
      );
      final active = await db.activeTimerDao.getActiveState();
      expect(active?.timerMode, 'focus');

      await db.activeTimerDao.clearActiveState();
      expect(await db.activeTimerDao.getActiveState(), isNull);
    });
  });
}
