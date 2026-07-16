import 'package:flutter/material.dart';

/// Semantic colors for Cramly's Learning Trace identity.
///
/// The original field names remain available as compatibility
/// aliases. New code should prefer the semantic roles near the bottom of the
/// class (`background`, `surface`, `foreground`, `primary`, and `poppy`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.bgCard,
    required this.bgCardHover,
    required this.bgElevated,
    required this.bgInput,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.accent,
    required this.accentHover,
    required this.accentSubtle,
    required this.primaryDeep,
    required this.poppy,
    required this.poppySubtle,
    required this.secondary,
    required this.secondarySubtle,
    required this.success,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.error,
    required this.errorSubtle,
  });

  final Color background;
  final Color bgCard;
  final Color bgCardHover;
  final Color bgElevated;
  final Color bgInput;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;

  /// Compatibility name for the primary evergreen action color.
  final Color accent;
  final Color accentHover;
  final Color accentSubtle;

  final Color primaryDeep;
  final Color poppy;
  final Color poppySubtle;
  final Color secondary;
  final Color secondarySubtle;
  final Color success;
  final Color successSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color error;
  final Color errorSubtle;

  // Preferred semantic names.
  Color get surface => bgCard;
  Color get surfaceSoft => bgCardHover;
  Color get surfaceRaised => bgElevated;
  Color get foreground => textPrimary;
  Color get muted => textMuted;
  Color get primary => accent;
  Color get danger => error;
  Color get dangerSubtle => errorSubtle;

  static const dark = AppColors(
    background: Color(0xFF101713),
    bgCard: Color(0xFF17211D),
    bgCardHover: Color(0xFF213029),
    bgElevated: Color(0xFF1D2924),
    bgInput: Color(0xFF17211D),
    border: Color(0x21EDF3F0),
    borderSubtle: Color(0x12EDF3F0),
    textPrimary: Color(0xFFEDF3F0),
    textSecondary: Color(0xFFC5D3CC),
    textMuted: Color(0xFFA6B6AE),
    textOnAccent: Color(0xFF101713),
    accent: Color(0xFF78B69E),
    accentHover: Color(0xFF91C6B1),
    accentSubtle: Color(0x2478B69E),
    primaryDeep: Color(0xFF0D2D25),
    poppy: Color(0xFFEF7464),
    poppySubtle: Color(0x24EF7464),
    secondary: Color(0xFF527D6C),
    secondarySubtle: Color(0x2E527D6C),
    success: Color(0xFF74C3A0),
    successSubtle: Color(0x2474C3A0),
    warning: Color(0xFFDDB36E),
    warningSubtle: Color(0x24DDB36E),
    error: Color(0xFFF18A81),
    errorSubtle: Color(0x24F18A81),
  );

  static const light = AppColors(
    background: Color(0xFFF4F7F5),
    bgCard: Color(0xFFFFFFFF),
    bgCardHover: Color(0xFFE8EFEB),
    bgElevated: Color(0xFFFFFFFF),
    bgInput: Color(0xFFFFFFFF),
    border: Color(0xFFCDD8D1),
    borderSubtle: Color(0x8FCDD8D1),
    textPrimary: Color(0xFF17211D),
    textSecondary: Color(0xFF435249),
    textMuted: Color(0xFF5F6E67),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF24594B),
    accentHover: Color(0xFF163A31),
    accentSubtle: Color(0x1F24594B),
    primaryDeep: Color(0xFF163A31),
    poppy: Color(0xFFC43F32),
    poppySubtle: Color(0x1FC43F32),
    secondary: Color(0xFFA9C8BA),
    secondarySubtle: Color(0x4DA9C8BA),
    success: Color(0xFF2F755C),
    successSubtle: Color(0x1F2F755C),
    warning: Color(0xFF9B681F),
    warningSubtle: Color(0x1F9B681F),
    error: Color(0xFFB63D35),
    errorSubtle: Color(0x1FB63D35),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? bgCard,
    Color? bgCardHover,
    Color? bgElevated,
    Color? bgInput,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnAccent,
    Color? accent,
    Color? accentHover,
    Color? accentSubtle,
    Color? primaryDeep,
    Color? poppy,
    Color? poppySubtle,
    Color? secondary,
    Color? secondarySubtle,
    Color? success,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? error,
    Color? errorSubtle,
  }) {
    return AppColors(
      background: background ?? this.background,
      bgCard: bgCard ?? this.bgCard,
      bgCardHover: bgCardHover ?? this.bgCardHover,
      bgElevated: bgElevated ?? this.bgElevated,
      bgInput: bgInput ?? this.bgInput,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      poppy: poppy ?? this.poppy,
      poppySubtle: poppySubtle ?? this.poppySubtle,
      secondary: secondary ?? this.secondary,
      secondarySubtle: secondarySubtle ?? this.secondarySubtle,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      error: error ?? this.error,
      errorSubtle: errorSubtle ?? this.errorSubtle,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgCardHover: Color.lerp(bgCardHover, other.bgCardHover, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      poppy: Color.lerp(poppy, other.poppy, t)!,
      poppySubtle: Color.lerp(poppySubtle, other.poppySubtle, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondarySubtle: Color.lerp(secondarySubtle, other.secondarySubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
