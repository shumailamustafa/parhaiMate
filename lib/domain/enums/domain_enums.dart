// Pure Dart domain enums (zero Flutter widget dependencies).

enum SubjectIdentifier {
  circle('circle', 'Circle'),
  square('square', 'Square'),
  triangle('triangle', 'Triangle'),
  diamond('diamond', 'Diamond'),
  ring('ring', 'Ring');

  const SubjectIdentifier(this.key, this.label);

  final String key;
  final String label;

  static SubjectIdentifier fromKey(String? raw) {
    return SubjectIdentifier.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => SubjectIdentifier.circle,
    );
  }
}

enum SubjectIconKey {
  sigma('sigma', 'Mathematics'),
  code('code', 'Programming'),
  database('database', 'Database'),
  chip('chip', 'Hardware'),
  language('language', 'Language'),
  atom('atom', 'Physics'),
  flask('flask', 'Chemistry'),
  globe('globe', 'Geography'),
  book('book', 'Literature'),
  pen('pen', 'Writing'),
  calculator('calculator', 'Accounting'),
  music('music', 'Arts');

  const SubjectIconKey(this.key, this.label);

  final String key;
  final String label;

  static SubjectIconKey fromKey(String? raw) {
    return SubjectIconKey.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => SubjectIconKey.book,
    );
  }
}

enum TimerMode {
  focus('focus', 'Focus Timer'),
  stopwatch('stopwatch', 'Stopwatch'),
  pomodoro('pomodoro', 'Pomodoro');

  const TimerMode(this.key, this.label);

  final String key;
  final String label;

  static TimerMode fromKey(String? raw) {
    return TimerMode.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => TimerMode.pomodoro,
    );
  }
}

enum TimerPhase {
  focusing('focusing', 'Focusing'),
  shortBreak('short_break', 'Short break'),
  longBreak('long_break', 'Long break');

  const TimerPhase(this.key, this.label);

  final String key;
  final String label;

  static TimerPhase fromKey(String? raw) {
    return TimerPhase.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => TimerPhase.focusing,
    );
  }
}

enum SessionStatus {
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const SessionStatus(this.key);

  final String key;

  static SessionStatus fromKey(String? raw) {
    return SessionStatus.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => SessionStatus.active,
    );
  }
}

enum StatsPeriod {
  week('Week'),
  month('Month'),
  year('Year');

  const StatsPeriod(this.label);

  final String label;
}

enum BackupRestoreMode {
  replace,
  merge,
}
