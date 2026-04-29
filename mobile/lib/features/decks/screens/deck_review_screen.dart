import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/deck_providers.dart';

class DeckReviewScreen extends ConsumerStatefulWidget {
  const DeckReviewScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckReviewScreen> createState() => _DeckReviewScreenState();
}

class _DeckReviewScreenState extends ConsumerState<DeckReviewScreen> {
  int _index = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckByIdProvider(widget.deckId));
    final cardsAsync = ref.watch(deckCardsProvider(widget.deckId));
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Review'),
      ),
      body: deckAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load deck\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.error),
          ),
        ),
        data: (deck) {
          if (deck == null) {
            return const EmptyState(
              title: 'Deck not found',
              subtitle: 'It may have been deleted.',
              icon: Icons.style_outlined,
            );
          }

          return cardsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Failed to load cards\n$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.error),
              ),
            ),
            data: (cards) {
              if (cards.isEmpty) {
                return const EmptyState(
                  title: 'No cards to review',
                  subtitle: 'Add cards first, then come back here.',
                  icon: Icons.flash_on_outlined,
                );
              }

              if (_index >= cards.length) {
                _index = cards.length - 1;
              }
              final card = cards[_index];

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.lg,
                    Spacing.xl,
                    Spacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deck.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          AppBadge(
                            label: '${_index + 1} / ${cards.length}',
                            color: AppBadgeColor.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.lg),
                      Expanded(
                        child: Center(
                          child: AppCard(
                            glow: true,
                            onTap: () => setState(() => _revealed = !_revealed),
                            child: AnimatedSwitcher(
                              duration: AppDurations.medium,
                              child: _revealed
                                  ? _AnswerFace(
                                      key: const ValueKey('answer'),
                                      back: card.back,
                                      explanation: card.explanation,
                                    )
                                  : _QuestionFace(
                                      key: const ValueKey('question'),
                                      front: card.front,
                                      hint: card.hint,
                                      topic: card.topic,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Previous',
                              variant: AppButtonVariant.secondary,
                              onPressed: _index > 0
                                  ? () => setState(() {
                                      _index--;
                                      _revealed = false;
                                    })
                                  : null,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: AppButton(
                              label: _revealed ? 'Hide answer' : 'Show answer',
                              onPressed: () =>
                                  setState(() => _revealed = !_revealed),
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: AppButton(
                              label: _index < cards.length - 1
                                  ? 'Next'
                                  : 'Done',
                              variant: AppButtonVariant.secondary,
                              onPressed: () {
                                if (_index < cards.length - 1) {
                                  setState(() {
                                    _index++;
                                    _revealed = false;
                                  });
                                  return;
                                }
                                context.pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestionFace extends StatelessWidget {
  const _QuestionFace({super.key, required this.front, this.hint, this.topic});

  final String front;
  final String? hint;
  final String? topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((topic ?? '').isNotEmpty) ...[
          AppBadge(label: topic!, color: AppBadgeColor.accent),
          const SizedBox(height: Spacing.md),
        ],
        Text(
          'Question',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          front,
          style: TextStyle(
            fontSize: 22,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        if ((hint ?? '').isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text('Hint', style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: Spacing.xs),
          Text(
            hint!,
            style: TextStyle(fontSize: 15, height: 1.5, color: c.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _AnswerFace extends StatelessWidget {
  const _AnswerFace({super.key, required this.back, this.explanation});

  final String back;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          back,
          style: TextStyle(
            fontSize: 22,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        if ((explanation ?? '').isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text(
            'Explanation',
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            explanation!,
            style: TextStyle(fontSize: 15, height: 1.6, color: c.textSecondary),
          ),
        ],
      ],
    );
  }
}
