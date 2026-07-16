import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/learning_trace.dart';
import '../../jobs/data/async_job_model.dart';
import '../../jobs/providers/job_providers.dart';
import '../data/deck_model.dart';
import '../providers/deck_providers.dart';
import '../widgets/card_form_sheet.dart';
import '../widgets/deck_form_sheet.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckByIdProvider(deckId));
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Flashcard deck'),
        actions: [
          deckAsync.maybeWhen(
            data: (deck) => deck == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, color: c.error),
                    onPressed: () => _confirmDelete(context, ref, deck),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: deckAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          title: 'Couldn’t load this deck',
          subtitle: 'Check your connection and try again.',
          icon: Icons.cloud_off_outlined,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(deckByIdProvider(deckId)),
        ),
        data: (deck) {
          if (deck == null) {
            return const EmptyState(
              title: 'Deck not found',
              subtitle: 'It may have been deleted.',
              icon: Icons.style_outlined,
            );
          }
          return _Body(deck: deck);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete deck?'),
        content: Text('"${deck.title}" and all of its cards will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(deckRepositoryProvider).deleteDeck(deck.id);
      if (context.mounted) context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete deck: $e')));
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(deckCardsProvider(deck.id));
    final jobAsync = deck.jobId == null || deck.jobId!.isEmpty
        ? null
        : ref.watch(asyncJobByIdProvider(deck.jobId!));
    final job = jobAsync?.valueOrNull;
    final jobFailed = job?.status == AsyncJobStatus.failed;
    final effectiveStatus = jobFailed ? DeckStatus.failed : deck.status;
    final effectiveError = jobFailed
        ? (job?.errorMessage ?? deck.errorMessage)
        : deck.errorMessage;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          0,
          Spacing.xl,
          Spacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              deck: deck,
              progress: job?.progress ?? 0,
              status: effectiveStatus,
            ),
            const SizedBox(height: Spacing.sm),
            const LearningTrace(width: 112, height: 20),
            const SizedBox(height: Spacing.lg),
            _ActionRow(deck: deck, status: effectiveStatus),
            const SizedBox(height: Spacing.xl),
            Expanded(
              child: jobAsync?.hasError == true
                  ? EmptyState(
                      title: 'Couldn’t check generation status',
                      subtitle:
                          'The status listener stopped. Check your connection and try again.',
                      icon: Icons.cloud_off_outlined,
                      actionLabel: 'Try again',
                      onAction: () =>
                          ref.invalidate(asyncJobByIdProvider(deck.jobId!)),
                    )
                  : switch (effectiveStatus) {
                      DeckStatus.failed => _FailedState(
                        message: effectiveError,
                      ),
                      DeckStatus.queued || DeckStatus.generating =>
                        _PendingState(deck: deck, progress: job?.progress ?? 0),
                      DeckStatus.ready => cardsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => EmptyState(
                          title: 'Couldn’t load cards',
                          subtitle: 'Check your connection and try again.',
                          icon: Icons.cloud_off_outlined,
                          actionLabel: 'Try again',
                          onAction: () =>
                              ref.invalidate(deckCardsProvider(deck.id)),
                        ),
                        data: (cards) => cards.isEmpty
                            ? const EmptyState(
                                title: 'No cards yet',
                                subtitle:
                                    'Add a card manually or generate from a document.',
                                icon: Icons.flash_on_outlined,
                              )
                            : ListView.separated(
                                itemCount: cards.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: Spacing.sm),
                                itemBuilder: (_, i) =>
                                    _CardRow(deck: deck, card: cards[i]),
                              ),
                      ),
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.deck,
    required this.progress,
    required this.status,
  });

  final Deck deck;
  final int progress;
  final DeckStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.accentSubtle,
                  borderRadius: Radii.cardRadius,
                ),
                alignment: Alignment.center,
                child: Icon(
                  deck.generationMethod == DeckGenerationMethod.ai
                      ? Icons.auto_awesome
                      : Icons.style_outlined,
                  color: c.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(deck, status, progress),
                      style: TextStyle(fontSize: 13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deck.description.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(
              deck.description,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              AppBadge(
                label: status.label,
                color: switch (status) {
                  DeckStatus.ready => AppBadgeColor.success,
                  DeckStatus.failed => AppBadgeColor.error,
                  DeckStatus.generating => AppBadgeColor.accent,
                  DeckStatus.queued => AppBadgeColor.secondary,
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(Deck deck, DeckStatus status, int progress) {
    final count = '${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}';
    return switch (status) {
      DeckStatus.ready => '$count · ${deck.generationMethod.label}',
      DeckStatus.failed => 'Generation failed',
      DeckStatus.generating =>
        progress > 0 ? 'Generating... $progress%' : 'Generating...',
      DeckStatus.queued => progress > 0 ? 'Queued... $progress%' : 'Queued',
    };
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.deck, required this.status});

  final Deck deck;
  final DeckStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReview = status == DeckStatus.ready && deck.cardCount > 0;
    final canEdit = status == DeckStatus.ready || status == DeckStatus.failed;

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        AppButton(
          label: 'Review',
          icon: Icons.play_arrow,
          size: AppButtonSize.sm,
          onPressed: canReview
              ? () => context.push(
                  '/library/${deck.courseId}/deck/${deck.id}/review',
                )
              : null,
        ),
        AppButton(
          label: 'Add card',
          icon: Icons.add,
          size: AppButtonSize.sm,
          variant: AppButtonVariant.secondary,
          onPressed: canEdit
              ? () async {
                  await showCardFormSheet(context, deckId: deck.id);
                }
              : null,
        ),
        AppButton(
          label: 'Edit deck',
          icon: Icons.edit_outlined,
          size: AppButtonSize.sm,
          variant: AppButtonVariant.ghost,
          onPressed: canEdit
              ? () async {
                  await showDeckFormSheet(
                    context,
                    courseId: deck.courseId,
                    existing: deck,
                  );
                }
              : null,
        ),
      ],
    );
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState({required this.deck, required this.progress});

  final Deck deck;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = progress <= 0 ? null : progress / 100;

    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                color: c.accent,
                backgroundColor: c.border,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              deck.status == DeckStatus.generating
                  ? 'Building your flashcards'
                  : 'Flashcards queued',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              progress > 0
                  ? 'Current progress: $progress%'
                  : 'The worker will pick this up automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      borderColor: c.error.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Flashcard generation failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.error,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            message ?? 'Unknown error.',
            style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CardRow extends ConsumerWidget {
  const _CardRow({required this.deck, required this.card});

  final Deck deck;
  final DeckCardItem card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return AppCard(
      onTap: () => showCardFormSheet(context, deckId: deck.id, existing: card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.front,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: c.error, size: 20),
                tooltip: 'Delete card',
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            card.back,
            style: TextStyle(fontSize: 14, height: 1.6, color: c.textPrimary),
          ),
          if ((card.hint ?? '').isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'Hint: ${card.hint}',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
          if ((card.explanation ?? '').isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              'Why it matters: ${card.explanation}',
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This flashcard will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(deckRepositoryProvider).deleteCard(deck.id, card.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete card: $e')));
    }
  }
}
