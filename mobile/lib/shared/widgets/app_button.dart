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
      AppButtonVariant.primary => (c.primary, c.textOnAccent, c.primary),
      AppButtonVariant.secondary => (c.surface, c.foreground, c.border),
      AppButtonVariant.ghost => (
        Colors.transparent,
        c.primary,
        Colors.transparent,
      ),
      AppButtonVariant.destructive => (
        Colors.transparent,
        c.danger,
        c.danger.withValues(alpha: 0.38),
      ),
    };

    final (height, horizontalPadding, fontSize, iconSize) = switch (size) {
      AppButtonSize.sm => (44.0, 14.0, 13.0, 16.0),
      AppButtonSize.md => (48.0, 18.0, 15.0, 18.0),
      AppButtonSize.lg => (52.0, 20.0, 16.0, 19.0),
    };

    final contents = Row(
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
        else ...[
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: Spacing.sm),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );

    final button = Semantics(
      button: true,
      enabled: !disabled,
      label: busy ? '$label, in progress' : label,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: disabled ? 0.47 : 1,
          duration: context.reduceMotion ? Duration.zero : AppDurations.control,
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: Radii.buttonRadius,
              side: BorderSide(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: disabled ? null : onPressed,
              focusColor: c.poppySubtle,
              hoverColor: variant == AppButtonVariant.primary
                  ? c.textOnAccent.withValues(alpha: 0.08)
                  : c.surfaceSoft,
              highlightColor: c.primary.withValues(alpha: 0.1),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 44, minHeight: height),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(child: contents),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
