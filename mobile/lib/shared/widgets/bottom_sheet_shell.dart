import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Standard 18px-top-radius mobile sheet content shell.
class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.page,
            Spacing.sm,
            Spacing.page,
            Spacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: AppTheme.display(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: c.foreground,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
