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

  /// Reserved for draggable/review cards; ordinary grouped surfaces stay flat.
  final bool glow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = borderColor ?? (glow ? c.primary : c.border);
    final decoration = BoxDecoration(
      color: c.surface,
      borderRadius: Radii.cardRadius,
      border: Border.all(color: glow ? border.withValues(alpha: 0.45) : border),
      boxShadow: glow
          ? [
              BoxShadow(
                color: c.primaryDeep.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
    );

    if (onTap == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    return Semantics(
      button: true,
      child: Material(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: glow ? 6 : 0,
        shadowColor: c.primaryDeep.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardRadius,
          side: BorderSide(
            color: glow ? border.withValues(alpha: 0.45) : border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          focusColor: c.poppySubtle,
          hoverColor: c.surfaceSoft.withValues(alpha: 0.7),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
