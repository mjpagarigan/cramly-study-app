import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

enum AppBadgeColor { accent, secondary, success, error }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color = AppBadgeColor.accent,
  });

  final String label;
  final AppBadgeColor color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (color) {
      AppBadgeColor.accent => (c.accentSubtle, c.accent),
      AppBadgeColor.secondary => (c.secondarySubtle, c.secondary),
      AppBadgeColor.success => (c.successSubtle, c.success),
      AppBadgeColor.error => (c.errorSubtle, c.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.pillRadius),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
