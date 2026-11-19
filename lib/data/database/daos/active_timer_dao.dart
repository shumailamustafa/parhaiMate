import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/active_timer_state_table.dart';

part 'active_timer_dao.g.dart';

@DriftAccessor(tables: <Type>[ActiveTimerStates])
class ActiveTimerDao extends DatabaseAccessor<AppDatabase>
    with _$ActiveTimerDaoMixin {
  ActiveTimerDao(super.db);

  static const int singleRowId = 1;

  Future<ActiveTimerState?> getActiveState() {
    return (select(activeTimerStates)
          ..where((t) => t.id.equals(singleRowId)))
        .getSingleOrNull();
  }

  Stream<ActiveTimerState?> watchActiveState() {
    return (select(activeTimerStates)
          ..where((t) => t.id.equals(singleRowId)))
        .watchSingleOrNull();
  }

  Future<void> saveActiveState(ActiveTimerStatesCompanion entry) {
    return into(activeTimerStates).insertOnConflictUpdate(
      entry.copyWith(id: const Value<int>(singleRowId)),
    );
  }

  Future<int> clearActiveState() {
    return (delete(activeTimerStates)
          ..where((t) => t.id.equals(singleRowId)))
        .go();
  }
}
