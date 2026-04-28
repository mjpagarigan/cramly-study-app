import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

/// Wraps content in the standard sheet styling: rounded top, padding, optional title.
/// Use with `showModalBottomSheet(builder: (_) => BottomSheetShell(...))`.
class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      // Lift content above the keyboard.
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.sm,
            Spacing.xl,
            Spacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.lg),
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
