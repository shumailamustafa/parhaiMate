import 'package:flutter/material.dart';

import '../../domain/enums/domain_enums.dart';

export '../../domain/enums/domain_enums.dart'
    show SubjectIconKey, SubjectIdentifier, TimerMode;

extension SubjectIconKeyVisual on SubjectIconKey {
  IconData get iconData {
    switch (this) {
      case SubjectIconKey.sigma:
        return Icons.functions_rounded;
      case SubjectIconKey.code:
        return Icons.code_rounded;
      case SubjectIconKey.database:
        return Icons.storage_rounded;
      case SubjectIconKey.chip:
        return Icons.memory_rounded;
      case SubjectIconKey.language:
        return Icons.translate_rounded;
      case SubjectIconKey.atom:
        return Icons.hub_outlined;
      case SubjectIconKey.flask:
        return Icons.science_outlined;
      case SubjectIconKey.globe:
        return Icons.public_rounded;
      case SubjectIconKey.book:
        return Icons.menu_book_rounded;
      case SubjectIconKey.pen:
        return Icons.edit_outlined;
      case SubjectIconKey.calculator:
        return Icons.calculate_outlined;
      case SubjectIconKey.music:
        return Icons.music_note_rounded;
    }
  }
}

extension TimerModeVisual on TimerMode {
  IconData get iconData {
    switch (this) {
      case TimerMode.focus:
        return Icons.track_changes_rounded;
      case TimerMode.stopwatch:
        return Icons.access_time_rounded;
      case TimerMode.pomodoro:
        return Icons.hourglass_empty_rounded;
    }
  }
}
