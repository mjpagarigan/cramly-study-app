import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_page_header.dart';
import '../../shared/widgets/learning_trace.dart';
import '../decks/data/deck_model.dart';
import '../decks/providers/deck_providers.dart';
import 'study_hub_data.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksProvider);
    final hub = decksAsync.valueOrNull == null
        ? null
        : deriveStudyHub(decksAsync.valueOrNull!);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allDecksProvider);
          try {
            await ref.read(allDecksProvider.future);
          } catch (_) {
            // The inline deck state reports the listener failure.
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
            const AppPageHeader(
              eyebrow: 'Choose a deck',
              title: 'Study',
              subtitle: 'Review cards in their saved order.',
            ),
            const SizedBox(height: Spacing.lg),
            _StudyHero(
              featuredDeck: hub?.featuredDeck,
              isLoading: hub == null && !decksAsync.hasError,
              hasError: hub == null && decksAsync.hasError,
              hasDecks: hub?.decks.isNotEmpty ?? false,
              onRetry: () => ref.invalidate(allDecksProvider),
            ),
            _StudySectionHeading(
              title: 'Your decks',
              actionLabel: hub?.decks.isNotEmpty == true ? 'Manage' : null,
              onAction: hub?.decks.isNotEmpty == true
                  ? () => context.go('/library')
                  : null,
            ),
            if (hub == null)
              _DeckListMessage(
                message: decksAsync.hasError
                    ? 'Cramly could not load your decks.'
                    : 'Loading your decks…',
              )
            else if (hub.decks.isEmpty)
              const _DeckListMessage(
                message: 'Decks you create or generate will be available here.',
              )
            else
              _DeckList(decks: hub.decks),
            const _StudySectionHeading(title: 'Coming later'),
            const _PlannedNotice(),
          ],
        ),
      ),
    );
  }
}

class _StudyHero extends StatelessWidget {
  const _StudyHero({
    required this.featuredDeck,
    required this.isLoading,
    required this.hasError,
    required this.hasDecks,
    required this.onRetry,
  });

  final Deck? featuredDeck;
  final bool isLoading;
  final bool hasError;
  final bool hasDecks;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = isLoading
        ? 'Finding a deck'
        : hasError
        ? 'Your decks are unavailable'
        : featuredDeck?.title ??
              (hasDecks ? 'No deck is ready yet' : 'Build your first deck');
    final body = isLoading
        ? 'Checking your saved decks…'
        : hasError
        ? 'Cramly could not refresh your decks. Try again.'
        : featuredDeck == null
        ? hasDecks
              ? 'Generating and empty decks stay in your library until they are ready to review.'
              : 'Create a manual deck or generate flashcards from a ready document.'
        : _deckDescription(featuredDeck!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.primaryDeep,
        borderRadius: Radii.surfaceRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LearningTrace(
              width: 240,
              color: const Color(0xFFC5D5CE),
              terminalColor: c.poppy,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              title,
              style: AppTheme.display(
                context,
                fontSize: 29,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF4F7F5),
                height: 1.03,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFC5D5CE),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 17),
            if (isLoading)
              const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF4F7F5),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (hasError)
              _StudyInvertedButton(label: 'Try again', onPressed: onRetry)
            else if (featuredDeck != null)
              _StudyInvertedButton(
                label: 'Review deck',
                onPressed: () => context.go(
                  '/library/${featuredDeck!.courseId}/deck/${featuredDeck!.id}/review',
                ),
              )
            else
              _StudyInvertedButton(
                label: 'Open Library',
                onPressed: () => context.go('/library'),
              ),
          ],
        ),
      ),
    );
  }

  static String _deckDescription(Deck deck) {
    if (deck.description.trim().isNotEmpty) return deck.description.trim();
    final cards = '${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}';
    final method = deck.generationMethod == DeckGenerationMethod.ai
        ? 'AI-generated'
        : 'Manual';
    return '$method · $cards';
  }
}

class _StudyInvertedButton extends StatelessWidget {
  const _StudyInvertedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: const Color(0xFFF4F7F5),
        shape: const RoundedRectangleBorder(borderRadius: Radii.controlRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          focusColor: c.poppySubtle,
          child: Center(
            child: Text(
              label,
              style: AppTheme.ui(
                context,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.primaryDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudySectionHeading extends StatelessWidget {
  const _StudySectionHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 27, bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                letterSpacing: -0.25,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _DeckList extends StatelessWidget {
  const _DeckList({required this.decks});

  final List<Deck> decks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.surfaceRadius,
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < decks.length; index++) ...[
            _DeckRow(deck: decks[index]),
            if (index < decks.length - 1) Divider(height: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => context.go('/library/${deck.courseId}/deck/${deck.id}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${deck.cardCount}',
                    style: AppTheme.mono(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.ui(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _metadata(deck),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: c.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(Icons.chevron_right, size: 20, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _metadata(Deck deck) {
    final cards = '${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}';
    if (deck.status == DeckStatus.ready) {
      return '${deck.generationMethod.label} · $cards';
    }
    return '${deck.status.label} · $cards';
  }
}

class _DeckListMessage extends StatelessWidget {
  const _DeckListMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: Radii.surfaceRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: c.muted),
        ),
      ),
    );
  }
}

class _PlannedNotice extends StatelessWidget {
  const _PlannedNotice();

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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adaptive daily review',
              style: AppTheme.ui(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Spaced-repetition ratings, due queues, quizzes, voice quiz, and study guides are planned—not active in this build.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: c.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
