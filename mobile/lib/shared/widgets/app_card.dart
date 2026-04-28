import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.glow = false,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = borderColor ??
        (glow ? c.accent.withValues(alpha: 0.15) : c.border);

    final container = Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: Radii.cardRadius,
        border: Border.all(color: border, width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.06),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      borderRadius: Radii.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardRadius,
        child: container,
      ),
    );
  }
}
