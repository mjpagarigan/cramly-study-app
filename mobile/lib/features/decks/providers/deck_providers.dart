import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_providers.dart';
import '../data/deck_model.dart';
import '../data/deck_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.watch(apiClientProvider));
});

final decksByCourseProvider = StreamProvider.family<List<Deck>, String>((
  ref,
  courseId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<Deck>>.empty();
  }
  return ref.watch(deckRepositoryProvider).watchByCourse(user.uid, courseId);
});

final deckByIdProvider = StreamProvider.family<Deck?, String>((ref, deckId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<Deck?>.empty();
  }
  return ref.watch(deckRepositoryProvider).watchById(user.uid, deckId);
});

final deckCardsProvider = StreamProvider.family<List<DeckCardItem>, String>((
  ref,
  deckId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<DeckCardItem>>.empty();
  }
  return ref.watch(deckRepositoryProvider).watchCards(user.uid, deckId);
});
