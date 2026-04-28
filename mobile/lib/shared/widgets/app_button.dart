import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.fullWidth = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = onPressed == null || busy;

    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (c.accent, c.textOnAccent, null),
      AppButtonVariant.secondary => (c.bgCard, c.textPrimary, c.border),
      AppButtonVariant.ghost => (Colors.transparent, c.accent, null),
      AppButtonVariant.destructive => (c.errorSubtle, c.error, null),
    };

    final padding = switch (size) {
      AppButtonSize.sm =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      AppButtonSize.md =>
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      AppButtonSize.lg =>
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    };

    final fontSize = switch (size) {
      AppButtonSize.sm => 13.0,
      AppButtonSize.md => 15.0,
      AppButtonSize.lg => 16.0,
    };

    final iconSize = size == AppButtonSize.sm ? 16.0 : 18.0;

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: Spacing.sm),
        ],
        if (!busy)
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: Radii.buttonRadius,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: Radii.buttonRadius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: Radii.buttonRadius,
              border: border != null ? Border.all(color: border) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
