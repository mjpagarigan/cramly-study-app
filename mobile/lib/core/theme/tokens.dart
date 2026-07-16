import 'package:flutter/widgets.dart';

/// Cramly's Learning Trace spacing scale.
///
/// Layouts should prefer these values to arbitrary gaps. The exported product
/// uses an eight-point base rhythm with a four-point half-step for compact UI.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double page = 20;
}

/// Radius roles from the approved brand direction.
abstract final class Radii {
  /// Buttons, fields, icon controls, and other focused controls.
  static const double control = 4;

  /// Cards, lists, notices, and other grouped surfaces.
  static const double surface = 12;

  /// Top corners of a mobile modal sheet.
  static const double sheet = 18;

  static const double full = 999;

  // Backwards-compatible aliases used throughout the existing feature code.
  static const double sm = control;
  static const double md = control;
  static const double lg = surface;
  static const double xl = sheet;

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(surface),
  );
  static const BorderRadius surfaceRadius = cardRadius;
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius controlRadius = buttonRadius;
  static const BorderRadius inputRadius = controlRadius;
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(full),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Motion timing follows retrieval: respond, return, resolve.
abstract final class AppDurations {
  static const Duration control = Duration(milliseconds: 180);
  static const Duration card = Duration(milliseconds: 320);
  static const Duration trace = Duration(milliseconds: 520);

  // Existing call sites use these names.
  static const Duration fast = control;
  static const Duration medium = card;
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
}

/// A single place for accessibility-aware motion decisions.
extension MotionPreferences on BuildContext {
  bool get reduceMotion {
    final media = MediaQuery.maybeOf(this);
    if (media == null) return false;
    return media.disableAnimations || media.accessibleNavigation;
  }
}
