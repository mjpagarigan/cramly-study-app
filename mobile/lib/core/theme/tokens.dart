import 'package:flutter/widgets.dart';

/// Design tokens lifted from the Front End System (theme.jsx).
/// Keep names and values in sync with that file — it's the source of truth.

abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(full));
  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
}
