import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Theme builders for the Nightowl design system.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors palette, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.textOnAccent,
      secondary: palette.secondary,
      onSecondary: palette.textOnAccent,
      surface: brightness == Brightness.dark
          ? const Color(0xFF0F1523)
          : const Color(0xFFF4F3F0),
      onSurface: palette.textPrimary,
      error: palette.error,
      onError: palette.textOnAccent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [palette],
    );

    final body = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    return base.copyWith(
      textTheme: body,
      primaryTextTheme: body,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: body.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary, size: 22),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.bgElevated,
        showDragHandle: true,
        dragHandleColor: palette.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.bgElevated,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// JetBrains Mono — used for stats / numeric callouts per the design system.
  static TextStyle mono(BuildContext context, {double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
