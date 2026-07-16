import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_page_header.dart';
import '../../shared/widgets/learning_trace.dart';
import '../decks/providers/deck_providers.dart';
import '../summaries/providers/summary_providers.dart';
import 'progress_data.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksProvider);
    final summariesAsync = ref.watch(allSummariesProvider);
    final decks = decksAsync.valueOrNull;
    final summaries = summariesAsync.valueOrNull;
    final progress = decks != null && summaries != null
        ? deriveProgressData(decks: decks, summaries: summaries)
        : null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _invalidate(ref);
          try {
            await Future.wait([
              ref.read(allDecksProvider.future),
              ref.read(allSummariesProvider.future),
            ]);
          } catch (_) {
            // The unavailable count and inline notice report the failure.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Spacing.page,
            Spacing.lg,
            Spacing.page,
            Spacing.xxxl,
          ),
          children: [
            const AppPageHeader(eyebrow: 'Learning history', title: 'Progress'),
            const SizedBox(height: 72),
            const Align(
              alignment: Alignment.center,
              child: LearningTrace(width: 120),
            ),
            const SizedBox(height: 18),
            Text(
              'Your learning trace starts here.',
              textAlign: TextAlign.center,
              style: AppTheme.display(
                context,
                fontSize: 29,
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  'Session analytics and mastery trends are planned. For now, Cramly keeps your documents, decks, and summaries organized without inventing progress scores.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            _ActivityList(
              deckValue: progress == null
                  ? _pendingValue(decksAsync)
                  : '${progress.deckCount}',
              summaryValue: progress == null
                  ? _pendingValue(summariesAsync)
                  : '${progress.summaryCount}',
              reviewValue: progress?.trackedReviewSessions ?? 'Not active',
            ),
            if (decksAsync.hasError || summariesAsync.hasError) ...[
              const SizedBox(height: Spacing.lg),
              _LoadNotice(onRetry: () => _invalidate(ref)),
            ],
          ],
        ),
      ),
    );
  }

  static String _pendingValue(AsyncValue<Object?> value) {
    return value.hasError ? 'Unavailable' : '—';
  }

  static void _invalidate(WidgetRef ref) {
    ref
      ..invalidate(allDecksProvider)
      ..invalidate(allSummariesProvider);
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.deckValue,
    required this.summaryValue,
    required this.reviewValue,
  });

  final String deckValue;
  final String summaryValue;
  final String reviewValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Available activity',
      child: Column(
        children: [
          _ActivityRow(label: 'Decks created', value: deckValue),
          Divider(height: 1, color: c.border),
          _ActivityRow(label: 'Summaries generated', value: summaryValue),
          Divider(height: 1, color: c.border),
          _ActivityRow(label: 'Tracked review sessions', value: reviewValue),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.ui(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Text(
            value,
            style: AppTheme.mono(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadNotice extends StatelessWidget {
  const _LoadNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        border: Border.all(color: c.border),
        borderRadius: Radii.surfaceRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Some activity counts could not be refreshed.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: c.muted),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
