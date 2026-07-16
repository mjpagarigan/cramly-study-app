import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

enum AppBadgeColor { accent, secondary, success, warning, error, planned }

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
      AppBadgeColor.accent => (c.accentSubtle, c.primary),
      AppBadgeColor.secondary => (c.surfaceSoft, c.textSecondary),
      AppBadgeColor.success => (c.successSubtle, c.success),
      AppBadgeColor.warning => (c.warningSubtle, c.warning),
      AppBadgeColor.error => (c.errorSubtle, c.error),
      AppBadgeColor.planned => (c.surfaceSoft, c.muted),
    };

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: Radii.pillRadius),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
