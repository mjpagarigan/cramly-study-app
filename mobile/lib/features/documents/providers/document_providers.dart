import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/document_model.dart';
import '../data/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(apiClientProvider));
});

/// Real-time stream of documents in a single course, newest first.
final documentsByCourseProvider =
    StreamProvider.family<List<Document>, String>((ref, courseId) {
  return ref.watch(documentRepositoryProvider).watchByCourse(courseId);
});

/// Single doc by id — used by the upload Processing screen and the detail screen.
final documentByIdProvider =
    StreamProvider.family<Document?, String>((ref, documentId) {
  return ref.watch(documentRepositoryProvider).watchById(documentId);
});

/// Lazily-loaded extracted text for a document.
final extractedTextProvider =
    FutureProvider.family<String?, String>((ref, extractedTextPath) {
  return ref.watch(documentRepositoryProvider).fetchExtractedText(extractedTextPath);
});
