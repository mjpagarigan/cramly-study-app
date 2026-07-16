import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_progress_bar.dart';
import '../../../shared/widgets/learning_trace.dart';
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
  bool _hintVisible = false;
  bool _complete = false;

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
        error: (_, _) => EmptyState(
          title: 'Couldn’t load this deck',
          subtitle: 'Check your connection and try again.',
          icon: Icons.cloud_off_outlined,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(deckByIdProvider(widget.deckId)),
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
            error: (_, _) => EmptyState(
              title: 'Couldn’t load review cards',
              subtitle: 'Check your connection and try again.',
              icon: Icons.cloud_off_outlined,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(deckCardsProvider(widget.deckId)),
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

              if (_complete) {
                return _CompletionView(
                  deckTitle: deck.title,
                  cardCount: cards.length,
                  onReviewAgain: () => setState(() {
                    _index = 0;
                    _revealed = false;
                    _hintVisible = false;
                    _complete = false;
                  }),
                  onFinish: () => context.pop(),
                );
              }
              final card = cards[_index];
              final reduceMotion =
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
                      AppButton(
                        label: _revealed ? 'Hide answer' : 'Show answer',
                        fullWidth: true,
                        onPressed: () => setState(() {
                          _revealed = !_revealed;
                          if (_revealed) _hintVisible = false;
                        }),
                      ),
                      const SizedBox(height: Spacing.sm),
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
                      const SizedBox(height: Spacing.sm),
                      const LearningTrace(width: 104, height: 18),
                      const SizedBox(height: Spacing.md),
                      AppProgressBar(
                        value: (_index + 1) / cards.length,
                        semanticLabel: 'Review progress',
                      ),
                      const SizedBox(height: Spacing.lg),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 320),
                            child: SizedBox(
                              width: double.infinity,
                              child: AppCard(
                                glow: true,
                                onTap: () => setState(() {
                                  _revealed = !_revealed;
                                  if (_revealed) _hintVisible = false;
                                }),
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: AnimatedSwitcher(
                                      duration: reduceMotion
                                          ? Duration.zero
                                          : AppDurations.medium,
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
                                              showHint: _hintVisible,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      if (!_revealed && (card.hint ?? '').isNotEmpty) ...[
                        AppButton(
                          label: _hintVisible ? 'Hide hint' : 'Show hint',
                          icon: Icons.lightbulb_outline,
                          variant: AppButtonVariant.ghost,
                          onPressed: () =>
                              setState(() => _hintVisible = !_hintVisible),
                        ),
                        const SizedBox(height: Spacing.sm),
                      ],
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
                                      _hintVisible = false;
                                    })
                                  : null,
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
                                    _hintVisible = false;
                                  });
                                  return;
                                }
                                setState(() => _complete = true);
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

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.deckTitle,
    required this.cardCount,
    required this.onReviewAgain,
    required this.onFinish,
  });

  final String deckTitle;
  final int cardCount;
  final VoidCallback onReviewAgain;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Review complete',
            child: AppCard(
              glow: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.check_circle_outline, color: c.success, size: 48),
                  const SizedBox(height: Spacing.sm),
                  const Align(
                    alignment: Alignment.center,
                    child: LearningTrace(width: 104, height: 18),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Review complete',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'You reached the end of “$deckTitle” — $cardCount ${cardCount == 1 ? 'card' : 'cards'} reviewed. No ratings or study history were recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: Spacing.xl),
                  AppButton(
                    label: 'Review again',
                    fullWidth: true,
                    onPressed: onReviewAgain,
                  ),
                  const SizedBox(height: Spacing.sm),
                  AppButton(
                    label: 'Back to deck',
                    fullWidth: true,
                    variant: AppButtonVariant.secondary,
                    onPressed: onFinish,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionFace extends StatelessWidget {
  const _QuestionFace({
    super.key,
    required this.front,
    required this.showHint,
    this.hint,
    this.topic,
  });

  final String front;
  final String? hint;
  final String? topic;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((topic ?? '').isNotEmpty) ...[
          Text(
            topic!.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c.primary,
              letterSpacing: 0.8,
            ),
          ),
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
        if ((hint ?? '').isNotEmpty && showHint) ...[
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
