import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'learning_trace.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.showTrace = false,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final bool showTrace;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: AppTheme.mono(
                    context,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ).copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(height: 7),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTheme.display(
                    context,
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    height: 1.02,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: c.muted),
                  ),
                ),
              ],
              if (showTrace) ...[
                const SizedBox(height: Spacing.md),
                const LearningTrace(),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Spacing.md), trailing!],
      ],
    );
  }
}
