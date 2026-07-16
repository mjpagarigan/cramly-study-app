import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.25,
                  color: c.foreground,
                ),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: Spacing.md),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
