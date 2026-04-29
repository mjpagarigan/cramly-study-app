import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/deck_model.dart';

class DeckRow extends StatelessWidget {
  const DeckRow({super.key, required this.deck, this.onTap});

  final Deck deck;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 46,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            alignment: Alignment.center,
            child: Icon(
              deck.generationMethod == DeckGenerationMethod.ai
                  ? Icons.auto_awesome
                  : Icons.style_outlined,
              size: 18,
              color: c.accent,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(deck),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          AppBadge(
            label: deck.status.label,
            color: switch (deck.status) {
              DeckStatus.ready => AppBadgeColor.success,
              DeckStatus.failed => AppBadgeColor.error,
              DeckStatus.generating => AppBadgeColor.accent,
              DeckStatus.queued => AppBadgeColor.secondary,
            },
          ),
        ],
      ),
    );
  }

  String _subtitle(Deck deck) {
    final parts = <String>[
      '${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}',
      deck.generationMethod.label,
    ];
    if (deck.description.isNotEmpty) {
      parts.add(deck.description);
    }
    return parts.join(' • ');
  }
}
