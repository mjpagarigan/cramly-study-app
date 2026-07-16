import '../decks/data/deck_model.dart';
import '../summaries/data/summary_model.dart';

class ProgressData {
  const ProgressData({required this.deckCount, required this.summaryCount});

  final int deckCount;
  final int summaryCount;

  /// Review events are not persisted by the current linear review flow.
  String get trackedReviewSessions => 'Not active';
}

/// Reports only counts backed by existing Firestore records.
ProgressData deriveProgressData({
  required List<Deck> decks,
  required List<Summary> summaries,
}) {
  return ProgressData(deckCount: decks.length, summaryCount: summaries.length);
}
