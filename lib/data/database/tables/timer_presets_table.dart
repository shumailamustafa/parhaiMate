import 'package:drift/drift.dart';

class TimerPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get timerMode =>
      text().named('timer_mode').withDefault(const Constant('pomodoro'))();
  IntColumn get focusMinutes => integer().named('focus_minutes')();
  IntColumn get shortBreakMinutes => integer().named('short_break_minutes')();
  IntColumn get longBreakMinutes => integer().named('long_break_minutes')();
  IntColumn get cyclesBeforeLongBreak =>
      integer().named('cycles_before_long_break')();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
}
