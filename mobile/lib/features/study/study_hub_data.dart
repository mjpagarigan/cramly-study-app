import '../decks/data/deck_model.dart';

class StudyHubData {
  const StudyHubData({required this.decks, required this.featuredDeck});

  final List<Deck> decks;
  final Deck? featuredDeck;
}

/// Orders the user's real decks and selects the newest reviewable one.
///
/// Cramly's current review flow is linear and write-free, so this intentionally
/// does not derive due dates, ratings, or a daily queue.
StudyHubData deriveStudyHub(List<Deck> source) {
  final decks = [...source]..sort(_newestDeckFirst);
  Deck? featuredDeck;
  for (final deck in decks) {
    if (isDeckReviewable(deck)) {
      featuredDeck = deck;
      break;
    }
  }
  return StudyHubData(
    decks: List.unmodifiable(decks),
    featuredDeck: featuredDeck,
  );
}

bool isDeckReviewable(Deck deck) =>
    deck.status == DeckStatus.ready && deck.cardCount > 0;

int _newestDeckFirst(Deck a, Deck b) {
  final aDate = a.updatedAt ?? a.createdAt;
  final bDate = b.updatedAt ?? b.createdAt;
  if (aDate == null && bDate == null) return a.id.compareTo(b.id);
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  return byDate == 0 ? a.id.compareTo(b.id) : byDate;
}
