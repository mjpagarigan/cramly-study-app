import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/learning_trace.dart';

/// Shown while Firebase restores the persisted session from disk.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final auth = ref.watch(authStateProvider);
    final hasError = auth.hasError;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 34),
                  const SizedBox(height: Spacing.xl),
                  const LearningTrace(width: 156),
                  const SizedBox(height: Spacing.xl),
                  if (hasError) ...[
                    Text(
                      'We could not restore your session.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Check your connection, then try again.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: Spacing.xl),
                    AppButton(
                      label: 'Try again',
                      onPressed: () => ref.invalidate(authStateProvider),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Restoring your session',
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'Restoring your session…',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
