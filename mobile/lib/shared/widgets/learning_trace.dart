import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

/// Cramly's signature Learning Trace.
///
/// Three offset, straight paths resolve through short angled joins into one
/// aligned terminal stroke. Keep this to one instance per composition.
class LearningTrace extends StatefulWidget {
  const LearningTrace({
    super.key,
    this.width = 136,
    this.height = 24,
    this.color,
    this.terminalColor,
    this.animate = true,
    this.semanticLabel,
  });

  final double width;
  final double height;
  final Color? color;
  final Color? terminalColor;
  final bool animate;
  final String? semanticLabel;

  @override
  State<LearningTrace> createState() => _LearningTraceState();
}

class _LearningTraceState extends State<LearningTrace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.trace,
    value: widget.animate ? 0 : 1,
  );
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = context.reduceMotion;
    if (!widget.animate || _reduceMotion) {
      _controller.value = 1;
      return;
    }
    if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LearningTrace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate) {
      _controller.value = 1;
    } else if (!oldWidget.animate && !_reduceMotion) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final branchColor = widget.color ?? c.primary;
    final terminalColor = widget.terminalColor ?? c.poppy;

    final trace = SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              for (var branch = 0; branch < 3; branch++)
                _AnimatedTracePart(
                  progress: _interval(
                    _controller.value,
                    branch * 0.1,
                    0.72 + branch * 0.08,
                  ),
                  horizontalOffset: 10 - branch * 2,
                  child: CustomPaint(
                    painter: _TraceBranchPainter(
                      branch: branch,
                      color: branchColor.withValues(alpha: 0.42 + branch * 0.2),
                    ),
                  ),
                ),
              _AnimatedTracePart(
                progress: _interval(_controller.value, 0.42, 1),
                horizontalOffset: 6,
                child: CustomPaint(
                  painter: _TraceTerminalPainter(color: terminalColor),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.semanticLabel == null) {
      return ExcludeSemantics(child: trace);
    }
    return Semantics(label: widget.semanticLabel, image: true, child: trace);
  }

  static double _interval(double value, double begin, double end) {
    return Curves.easeOutCubic.transform(
      ((value - begin) / (end - begin)).clamp(0.0, 1.0),
    );
  }
}

class _AnimatedTracePart extends StatelessWidget {
  const _AnimatedTracePart({
    required this.progress,
    required this.horizontalOffset,
    required this.child,
  });

  final double progress;
  final double horizontalOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(-horizontalOffset * (1 - progress), 0),
        child: child,
      ),
    );
  }
}

class _TraceBranchPainter extends CustomPainter {
  const _TraceBranchPainter({required this.branch, required this.color});

  final int branch;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final gap = math.min(6.0, size.height * 0.24);
    final startY = centerY + (branch - 1) * gap;
    final joinStartX = size.width * (0.48 + branch * 0.045);
    final meetingX = size.width * 0.69;
    final path = Path()
      ..moveTo(0, startY)
      ..lineTo(joinStartX, startY)
      ..lineTo(meetingX, centerY);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(covariant _TraceBranchPainter oldDelegate) {
    return branch != oldDelegate.branch || color != oldDelegate.color;
  }
}

class _TraceTerminalPainter extends CustomPainter {
  const _TraceTerminalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.69, y),
      Offset(size.width, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant _TraceTerminalPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
