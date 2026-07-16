import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_providers.dart';
import '../data/deck_model.dart';
import '../data/deck_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.watch(apiClientProvider));
});

final decksByCourseProvider = StreamProvider.autoDispose
    .family<List<Deck>, String>((ref, courseId) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream<List<Deck>>.empty();
      }
      return ref
          .watch(deckRepositoryProvider)
          .watchByCourse(user.uid, courseId);
    });

final deckByIdProvider = StreamProvider.autoDispose.family<Deck?, String>((
  ref,
  deckId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<Deck?>.empty();
  }
  return ref.watch(deckRepositoryProvider).watchById(user.uid, deckId);
});

final deckCardsProvider = StreamProvider.autoDispose
    .family<List<DeckCardItem>, String>((ref, deckId) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream<List<DeckCardItem>>.empty();
      }
      return ref.watch(deckRepositoryProvider).watchCards(user.uid, deckId);
    });

/// Real-time stream of every deck owned by the signed-in user.
final allDecksProvider = StreamProvider.autoDispose<List<Deck>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<Deck>>.empty();
  }
  return ref.watch(deckRepositoryProvider).watchAll(user.uid);
});
