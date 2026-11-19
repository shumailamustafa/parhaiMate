import 'package:drift/drift.dart';

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get achievementCode => text().named('achievement_code').unique()();
  IntColumn get unlockedAt => integer().named('unlocked_at').nullable()();
}
