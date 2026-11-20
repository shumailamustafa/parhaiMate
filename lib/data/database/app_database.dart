import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/achievement_dao.dart';
import 'daos/active_timer_dao.dart';
import 'daos/goal_streak_dao.dart';
import 'daos/planner_dao.dart';
import 'daos/preset_dao.dart';
import 'daos/session_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/subject_dao.dart';
import 'migrations/database_migrations.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Subjects,
    StudySessions,
    DailyGoals,
    PlannerTasks,
    TimerPresets,
    Achievements,
    StreakRecords,
    SessionEvents,
    AppSettings,
    ActiveTimerStates,
  ],
  daos: <Type>[
    SubjectDao,
    SessionDao,
    PlannerDao,
    GoalStreakDao,
    PresetDao,
    AchievementDao,
    SettingsDao,
    ActiveTimerDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  static const String keyDailyGoalMinutes = 'daily_goal_minutes';
  static const String keyWeeklyGoalMinutes = 'weekly_goal_minutes';
  static const String keyDefaultTimerMode = 'default_timer_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keySessionAlertsEnabled = 'session_alerts_enabled';
  static const String keyNotificationPromptShown = 'notification_prompt_shown';

  static const List<String> defaultAchievementCodes = <String>[
    'first_session',
    'focus_starter',
    'consistent_learner',
    'study_champion',
    'time_master',
    'weekly_warrior',
  ];

  @override
  int get schemaVersion => DatabaseMigrations.currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await DatabaseMigrations.createIndexes(m);
          await _seedInitialData();
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  Future<void> _seedInitialData() async {
    await batch((Batch b) {
      b.insertAllOnConflictUpdate(
        appSettings,
        <AppSettingsCompanion>[
          AppSettingsCompanion.insert(key: keyDailyGoalMinutes, value: '240'),
          AppSettingsCompanion.insert(key: keyWeeklyGoalMinutes, value: '1200'),
          AppSettingsCompanion.insert(
            key: keyDefaultTimerMode,
            value: 'pomodoro',
          ),
          AppSettingsCompanion.insert(
            key: keyOnboardingCompleted,
            value: 'false',
          ),
        ],
      );

      b.insertAll(
        timerPresets,
        <TimerPresetsCompanion>[
          TimerPresetsCompanion.insert(
            name: 'Classic Pomodoro',
            timerMode: const Value<String>('pomodoro'),
            focusMinutes: 25,
            shortBreakMinutes: 5,
            longBreakMinutes: 15,
            cyclesBeforeLongBreak: 4,
            isDefault: const Value<bool>(true),
          ),
          TimerPresetsCompanion.insert(
            name: 'Deep Work',
            timerMode: const Value<String>('focus'),
            focusMinutes: 50,
            shortBreakMinutes: 5,
            longBreakMinutes: 15,
            cyclesBeforeLongBreak: 4,
            isDefault: const Value<bool>(false),
          ),
          TimerPresetsCompanion.insert(
            name: 'Quick Review',
            timerMode: const Value<String>('focus'),
            focusMinutes: 15,
            shortBreakMinutes: 5,
            longBreakMinutes: 15,
            cyclesBeforeLongBreak: 4,
            isDefault: const Value<bool>(false),
          ),
        ],
      );

      b.insertAllOnConflictUpdate(
        achievements,
        defaultAchievementCodes
            .map(
              (code) => AchievementsCompanion.insert(achievementCode: code),
            )
            .toList(),
      );
    });
  }

  /// Ensures default presets, achievements, and baseline settings exist.
  Future<void> ensureDefaultsSeeded() async {
    final existingSettings = await settingsDao.getAllSettings();
    if (existingSettings.isEmpty) {
      await _seedInitialData();
      return;
    }
    for (final code in defaultAchievementCodes) {
      final existing = await achievementDao.getByCode(code);
      if (existing == null) {
        await into(achievements).insert(
          AchievementsCompanion.insert(achievementCode: code),
        );
      }
    }
  }

  /// Resets all user data while keeping default settings and locked achievements.
  Future<void> resetAllUserData() async {
    await transaction(() async {
      await delete(activeTimerStates).go();
      await delete(sessionEvents).go();
      await delete(studySessions).go();
      await delete(plannerTasks).go();
      await delete(subjects).go();
      await delete(dailyGoals).go();
      await delete(streakRecords).go();
      await delete(timerPresets).go();
      await delete(achievements).go();
      await delete(appSettings).go();
      await _seedInitialData();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'parhaimate.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
