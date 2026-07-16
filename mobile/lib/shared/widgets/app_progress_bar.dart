import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

/// A transform-based progress indicator that does not animate layout width.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.semanticLabel,
    this.animate = true,
  });

  final double value;
  final String? semanticLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = value.clamp(0.0, 1.0);
    final duration = animate && !context.reduceMotion
        ? AppDurations.card
        : Duration.zero;

    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()}%',
      child: ClipRRect(
        borderRadius: Radii.pillRadius,
        child: SizedBox(
          height: 5,
          child: ColoredBox(
            color: c.surfaceSoft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: target),
              duration: duration,
              curve: AppCurves.standard,
              builder: (_, progress, child) => Transform.scale(
                alignment: Alignment.centerLeft,
                scaleX: progress,
                child: child,
              ),
              child: ColoredBox(color: c.primary),
            ),
          ),
        ),
      ),
    );
  }
}
