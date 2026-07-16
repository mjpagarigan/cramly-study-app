import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/api/api_client.dart';
import 'deck_model.dart';

class DeckRepository {
  DeckRepository(this._api);

  final ApiClient _api;

  CollectionReference<Map<String, dynamic>> _collectionForUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('decks');
  }

  CollectionReference<Map<String, dynamic>> _cardsCollectionForUser(
    String uid,
    String deckId,
  ) {
    return _collectionForUser(uid).doc(deckId).collection('cards');
  }

  Stream<List<Deck>> watchByCourse(String uid, String courseId) {
    return _collectionForUser(uid)
        .where('courseId', isEqualTo: courseId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Deck.fromFirestore).toList());
  }

  /// Watches every deck owned by [uid], newest first, without requiring an
  /// additional Firestore index. Sorting client-side also keeps legacy decks
  /// without `updatedAt` visible.
  Stream<List<Deck>> watchAll(String uid) {
    return _collectionForUser(uid).snapshots().map((snap) {
      final decks = snap.docs.map(Deck.fromFirestore).toList();
      decks.sort(_newestDeckFirst);
      return decks;
    });
  }

  Stream<Deck?> watchById(String uid, String deckId) {
    return _collectionForUser(uid).doc(deckId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Deck.fromFirestore(snap);
    });
  }

  Stream<List<DeckCardItem>> watchCards(String uid, String deckId) {
    return _cardsCollectionForUser(uid, deckId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(DeckCardItem.fromFirestore).toList());
  }

  Future<DeckGenerationResult> generateDeck({
    required String documentId,
    required int cardCount,
  }) async {
    final json =
        await _api.post(
              '/documents/$documentId/generate',
              body: {'generator': 'flashcards', 'cardCount': cardCount},
            )
            as Map<String, dynamic>;
    return DeckGenerationResult.fromJson(json);
  }

  Future<Deck> createManualDeck({
    required String courseId,
    required String title,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'courseId': courseId,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
    };
    final json = await _api.post('/decks', body: body) as Map<String, dynamic>;
    return Deck.fromJson(json);
  }

  Future<Deck> updateDeck(
    String deckId, {
    String? title,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    final json =
        await _api.patch('/decks/$deckId', body: body) as Map<String, dynamic>;
    return Deck.fromJson(json);
  }

  Future<void> deleteDeck(String deckId) async {
    await _api.delete('/decks/$deckId');
  }

  Future<DeckCardItem> createCard(
    String deckId, {
    required String front,
    required String back,
    String? hint,
    String? explanation,
    String? topic,
  }) async {
    final body = <String, dynamic>{
      'front': front,
      'back': back,
      if (hint != null && hint.isNotEmpty) 'hint': hint,
      if (explanation != null && explanation.isNotEmpty)
        'explanation': explanation,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    };
    final json =
        await _api.post('/decks/$deckId/cards', body: body)
            as Map<String, dynamic>;
    return DeckCardItem.fromJson(json);
  }

  Future<DeckCardItem> updateCard(
    String deckId,
    String cardId, {
    String? front,
    String? back,
    String? hint,
    String? explanation,
    String? topic,
  }) async {
    final body = <String, dynamic>{};
    if (front != null) body['front'] = front;
    if (back != null) body['back'] = back;
    if (hint != null) body['hint'] = hint;
    if (explanation != null) body['explanation'] = explanation;
    if (topic != null) body['topic'] = topic;
    final json =
        await _api.patch('/decks/$deckId/cards/$cardId', body: body)
            as Map<String, dynamic>;
    return DeckCardItem.fromJson(json);
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    await _api.delete('/decks/$deckId/cards/$cardId');
  }
}

int _newestDeckFirst(Deck a, Deck b) {
  final aDate = a.updatedAt ?? a.createdAt;
  final bDate = b.updatedAt ?? b.createdAt;
  if (aDate == null && bDate == null) return a.id.compareTo(b.id);
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  return byDate == 0 ? a.id.compareTo(b.id) : byDate;
}
