import 'package:flutter/widgets.dart';

/// Consistent border radius tokens across ParhaiMate.
abstract final class AppRadii {
  static const double control = 14;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;

  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetTopRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
