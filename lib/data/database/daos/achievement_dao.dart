import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/achievements_table.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: <Type>[Achievements])
class AchievementDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  Stream<List<Achievement>> watchAllAchievements() {
    return (select(achievements)
          ..orderBy(<OrderingTerm Function(Achievements)>[
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<List<Achievement>> getAllAchievements() {
    return (select(achievements)
          ..orderBy(<OrderingTerm Function(Achievements)>[
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<Achievement?> getByCode(String code) {
    return (select(achievements)..where((t) => t.achievementCode.equals(code)))
        .getSingleOrNull();
  }

  Future<void> unlockAchievement(String code, int unlockedAtMs) async {
    final existing = await getByCode(code);
    if (existing == null) {
      await into(achievements).insert(
        AchievementsCompanion.insert(
          achievementCode: code,
          unlockedAt: Value<int?>(unlockedAtMs),
        ),
      );
      return;
    }
    if (existing.unlockedAt == null) {
      await (update(achievements)
            ..where((t) => t.achievementCode.equals(code)))
          .write(
        AchievementsCompanion(unlockedAt: Value<int?>(unlockedAtMs)),
      );
    }
  }

  Future<int> resetAllUnlocks() {
    return update(achievements).write(
      const AchievementsCompanion(unlockedAt: Value<int?>(null)),
    );
  }
}
