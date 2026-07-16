import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'tokens.dart';

/// Theme builders for Cramly's approved Learning Trace design system.
abstract final class AppTheme {
  static const String displayFamily = 'Newsreader';
  static const String bodyFamily = 'Manrope';
  static const String monoFamily = 'IBM Plex Mono';

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors palette, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.textOnAccent,
      secondary: palette.secondary,
      onSecondary: palette.foreground,
      surface: palette.surface,
      onSurface: palette.foreground,
      error: palette.danger,
      onError: brightness == Brightness.dark
          ? palette.background
          : const Color(0xFFFFFFFF),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      fontFamily: bodyFamily,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      focusColor: palette.poppy.withValues(alpha: 0.22),
      hoverColor: palette.primary.withValues(alpha: 0.06),
      highlightColor: palette.primary.withValues(alpha: 0.09),
      extensions: [palette],
    );

    final textTheme = _textTheme(base.textTheme, palette);
    final controlShape = RoundedRectangleBorder(
      borderRadius: Radii.controlRadius,
    );
    final controlPadding = const EdgeInsets.symmetric(
      horizontal: Spacing.lg,
      vertical: Spacing.md,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.foreground, size: 22),
        actionsIconTheme: IconThemeData(color: palette.foreground, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.surfaceRadius,
          side: BorderSide(color: palette.border),
        ),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary, size: 22),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.bgInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.muted),
        labelStyle: textTheme.labelLarge?.copyWith(color: palette.foreground),
        helperStyle: textTheme.bodySmall?.copyWith(color: palette.muted),
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.danger),
        border: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: palette.danger, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: controlPadding,
          backgroundColor: palette.primary,
          foregroundColor: palette.textOnAccent,
          disabledBackgroundColor: palette.primary.withValues(alpha: 0.4),
          disabledForegroundColor: palette.textOnAccent.withValues(alpha: 0.8),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: controlPadding,
          foregroundColor: palette.foreground,
          side: BorderSide(color: palette.border),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: palette.primary,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: palette.foreground,
          shape: controlShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.textOnAccent,
        elevation: 6,
        focusElevation: 7,
        hoverElevation: 7,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.muted,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x7A080F0C),
        showDragHandle: true,
        dragHandleColor: palette.border,
        dragHandleSize: const Size(38, 4),
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: Radii.surfaceRadius),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.primaryDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFF4F7F5),
        ),
        actionTextColor: const Color(0xFFF4F7F5),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceSoft,
        circularTrackColor: palette.surfaceSoft,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceSoft,
        selectedColor: palette.accentSubtle,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelSmall?.copyWith(color: palette.primary),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppColors palette) {
    TextStyle body({
      double? size,
      double? height,
      FontWeight? weight,
      double? tracking,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: tracking,
        color: color ?? palette.foreground,
      );
    }

    TextStyle display({
      required double size,
      required double height,
      FontWeight weight = FontWeight.w600,
      double tracking = -0.6,
    }) {
      return TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: tracking,
        color: palette.foreground,
      );
    }

    return base.copyWith(
      displayLarge: display(size: 48, height: 1.05, tracking: -1.2),
      displayMedium: display(size: 38, height: 1.05, tracking: -0.95),
      displaySmall: display(size: 36, height: 1.1, tracking: -0.72),
      headlineLarge: display(size: 32, height: 1.15, weight: FontWeight.w500),
      headlineMedium: display(size: 28, height: 1.15, weight: FontWeight.w500),
      headlineSmall: display(size: 24, height: 1.18, weight: FontWeight.w500),
      titleLarge: body(size: 20, height: 1.25, weight: FontWeight.w600),
      titleMedium: body(size: 16, height: 1.3, weight: FontWeight.w600),
      titleSmall: body(size: 14, height: 1.35, weight: FontWeight.w600),
      bodyLarge: body(size: 16, height: 1.55, weight: FontWeight.w400),
      bodyMedium: body(size: 14, height: 1.5, weight: FontWeight.w400),
      bodySmall: body(
        size: 12,
        height: 1.45,
        weight: FontWeight.w400,
        color: palette.muted,
      ),
      labelLarge: body(
        size: 15,
        height: 1.2,
        weight: FontWeight.w600,
        tracking: 0.15,
      ),
      labelMedium: body(
        size: 13,
        height: 1.2,
        weight: FontWeight.w600,
        tracking: 0.13,
      ),
      labelSmall: TextStyle(
        fontFamily: monoFamily,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.66,
        color: palette.muted,
      ),
    );
  }

  static TextStyle display(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return (Theme.of(context).textTheme.displayMedium ?? const TextStyle())
        .copyWith(
          fontFamily: displayFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
  }

  static TextStyle ui(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
        .copyWith(
          fontFamily: bodyFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
  }

  static TextStyle mono(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
        .copyWith(
          fontFamily: monoFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
  }
}
