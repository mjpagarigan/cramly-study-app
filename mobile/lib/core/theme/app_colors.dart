import 'package:flutter/material.dart';

/// Custom palette beyond what `ColorScheme` covers — accents, card surfaces,
/// muted text variants, etc. Mirrors `theme.jsx` from the Front End System.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
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
    required this.secondary,
    required this.secondarySubtle,
    required this.success,
    required this.successSubtle,
    required this.error,
    required this.errorSubtle,
  });

  final Color bgCard;
  final Color bgCardHover;
  final Color bgElevated;
  final Color bgInput;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  // Used on top of solid accent surfaces (button labels, FAB icons).
  final Color textOnAccent;
  final Color accent;
  final Color accentHover;
  final Color accentSubtle;
  final Color secondary;
  final Color secondarySubtle;
  final Color success;
  final Color successSubtle;
  final Color error;
  final Color errorSubtle;

  static const dark = AppColors(
    bgCard: Color(0xFF171E30),
    bgCardHover: Color(0xFF1C2438),
    bgElevated: Color(0xFF1E2538),
    bgInput: Color(0xFF1A2235),
    border: Color(0x0FFFFFFF),
    borderSubtle: Color(0x08FFFFFF),
    textPrimary: Color(0xFFE0DFE4),
    textSecondary: Color(0xFF8890A8),
    textMuted: Color(0xFF6B7394),
    textOnAccent: Color(0xFF0F1523),
    accent: Color(0xFFE8A84C),
    accentHover: Color(0xFFF0B860),
    accentSubtle: Color(0x1FE8A84C),
    secondary: Color(0xFF4CC8E8),
    secondarySubtle: Color(0x1F4CC8E8),
    success: Color(0xFF5CB87A),
    successSubtle: Color(0x1F5CB87A),
    error: Color(0xFFE85C5C),
    errorSubtle: Color(0x1FE85C5C),
  );

  static const light = AppColors(
    bgCard: Color(0xFFFFFFFF),
    bgCardHover: Color(0xFFF9F8F6),
    bgElevated: Color(0xFFFFFFFF),
    bgInput: Color(0xFFEEECEA),
    border: Color(0x14000000),
    borderSubtle: Color(0x0A000000),
    textPrimary: Color(0xFF1A1E2E),
    textSecondary: Color(0xFF6B6860),
    textMuted: Color(0xFF9A9890),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFD49540),
    accentHover: Color(0xFFC08530),
    accentSubtle: Color(0x1FD49540),
    secondary: Color(0xFF3AA8C4),
    secondarySubtle: Color(0x1F3AA8C4),
    success: Color(0xFF4A9E65),
    successSubtle: Color(0x1F4A9E65),
    error: Color(0xFFD04848),
    errorSubtle: Color(0x1FD04848),
  );

  @override
  AppColors copyWith({
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
    Color? secondary,
    Color? secondarySubtle,
    Color? success,
    Color? successSubtle,
    Color? error,
    Color? errorSubtle,
  }) {
    return AppColors(
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
      secondary: secondary ?? this.secondary,
      secondarySubtle: secondarySubtle ?? this.secondarySubtle,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      error: error ?? this.error,
      errorSubtle: errorSubtle ?? this.errorSubtle,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
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
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondarySubtle:
          Color.lerp(secondarySubtle, other.secondarySubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
