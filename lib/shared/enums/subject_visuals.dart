import 'package:flutter/material.dart';

/// Neutral geometric shape identifiers used beside subject names.
///
/// Replaces colorful subject accents to uphold ParhaiMate's monochrome + navy UI.
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

/// Twelve monochrome subject icons matching the Add Subject picker grid.
enum SubjectIconKey {
  sigma('sigma', 'Mathematics', Icons.functions_rounded),
  code('code', 'Programming', Icons.code_rounded),
  database('database', 'Database', Icons.storage_rounded),
  chip('chip', 'Hardware', Icons.memory_rounded),
  language('language', 'Language', Icons.translate_rounded),
  atom('atom', 'Physics', Icons.hub_outlined),
  flask('flask', 'Chemistry', Icons.science_outlined),
  globe('globe', 'Geography', Icons.public_rounded),
  book('book', 'Literature', Icons.menu_book_rounded),
  pen('pen', 'Writing', Icons.edit_outlined),
  calculator('calculator', 'Accounting', Icons.calculate_outlined),
  music('music', 'Arts', Icons.music_note_rounded);

  const SubjectIconKey(this.key, this.label, this.iconData);

  final String key;
  final String label;
  final IconData iconData;

  static SubjectIconKey fromKey(String? raw) {
    return SubjectIconKey.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => SubjectIconKey.book,
    );
  }
}

/// Study timing modes supported by the timer engine and UI.
enum TimerMode {
  focus('focus', 'Focus Timer', Icons.track_changes_rounded),
  stopwatch('stopwatch', 'Stopwatch', Icons.access_time_rounded),
  pomodoro('pomodoro', 'Pomodoro', Icons.hourglass_empty_rounded);

  const TimerMode(this.key, this.label, this.iconData);

  final String key;
  final String label;
  final IconData iconData;

  static TimerMode fromKey(String? raw) {
    return TimerMode.values.firstWhere(
      (value) => value.key == raw,
      orElse: () => TimerMode.pomodoro,
    );
  }
}
