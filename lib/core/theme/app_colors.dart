import 'package:flutter/material.dart';

/// Strict ParhaiMate V1 color tokens.
///
/// Only pure white, pure black, navy blue (#123B52), and neutral greys are
/// permitted across every screen, card, icon, chart, and illustration.
abstract final class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF000000);
  static const Color primary = Color(0xFF123B52);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFF0F0F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E4E4);
  static const Color divider = Color(0xFFEDEDED);
  static const Color track = Color(0xFFDCDCDC);
  static const Color disabled = Color(0xFFC8C8C8);
  static const Color destructive = Color(0xFF000000);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textMuted = Color(0xFF8A8A8A);

  /// Strict monochrome + navy chart segments (no colorful accents or gradients).
  static const List<Color> chartPalette = <Color>[
    Color(0xFF123B52),
    Color(0xFF000000),
    Color(0xFF555555),
    Color(0xFF8A8A8A),
    Color(0xFFDCDCDC),
  ];

  static const Color barrierScrim = Color(0x66000000);
}
