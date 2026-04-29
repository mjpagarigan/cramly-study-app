import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/api/api_client.dart';
import '../data/document_model.dart';
import '../data/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(apiClientProvider));
});

/// Real-time stream of documents in a single course, newest first.
final documentsByCourseProvider =
    StreamProvider.family<List<Document>, String>((ref, courseId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<Document>>.empty();
  }
  return ref.watch(documentRepositoryProvider).watchByCourse(
        user.uid,
        courseId,
      );
});

/// Single doc by id — used by the upload Processing screen and the detail screen.
final documentByIdProvider =
    StreamProvider.family<Document?, String>((ref, documentId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<Document?>.empty();
  }
  return ref.watch(documentRepositoryProvider).watchById(
        user.uid,
        documentId,
      );
});

/// Lazily-loaded extracted text for a document.
final extractedTextProvider =
    FutureProvider.family<String?, String>((ref, extractedTextPath) {
  return ref.watch(documentRepositoryProvider).fetchExtractedText(extractedTextPath);
});
