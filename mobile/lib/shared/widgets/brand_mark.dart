import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 26,
    this.showWordmark = true,
    this.color,
  });

  final double size;
  final bool showWordmark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Cramly',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _BrandMarkPainter(
                primary: color ?? c.primary,
                poppy: c.poppy,
              ),
            ),
            if (showWordmark) ...[
              const SizedBox(width: 10),
              Text(
                'Cramly',
                style: AppTheme.ui(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.primary, required this.poppy});

  final Color primary;
  final Color poppy;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final inner = outer.deflate(size.width * 0.2);
    final gapStart = -0.58;
    final sweep = 5.18;
    canvas
      ..drawArc(
        outer,
        gapStart,
        sweep,
        false,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawArc(
        inner,
        gapStart,
        sweep,
        false,
        Paint()
          ..color = poppy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) {
    return primary != oldDelegate.primary || poppy != oldDelegate.poppy;
  }
}
