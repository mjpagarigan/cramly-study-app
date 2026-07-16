import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.add,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: Radii.cardRadius,
            ),
            child: Icon(icon, color: c.primary, size: 23),
          ),
          const SizedBox(height: Spacing.lg),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.display(
                context,
                fontSize: 29,
                fontWeight: FontWeight.w500,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.muted, height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Spacing.xl),
            AppButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.xxxl,
        );
        if (!constraints.hasBoundedHeight) {
          return Center(
            child: Padding(padding: padding, child: content),
          );
        }
        final innerHeight = constraints.maxHeight - padding.vertical;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: innerHeight > 0 ? innerHeight : 0,
            ),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
