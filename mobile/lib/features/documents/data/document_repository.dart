import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/api/api_client.dart';
import 'document_model.dart';

class UploadProgress {
  const UploadProgress({required this.transferred, required this.total});
  final int transferred;
  final int total;
  double get fraction => total == 0 ? 0 : transferred / total;
}

/// Reads via Firestore listener (real-time + offline cache).
/// Uploads go to Firebase Storage directly per spec §7.2.
/// Document creation/extraction/deletion go through FastAPI.
class DocumentRepository {
  DocumentRepository(this._api);
  final ApiClient _api;

  String _uid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('DocumentRepository requires a signed-in user');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _collection() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid())
        .collection('documents');
  }

  CollectionReference<Map<String, dynamic>> _collectionForUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('documents');
  }

  /// Stream of all documents for one course, ordered newest first.
  Stream<List<Document>> watchByCourse(String uid, String courseId) {
    return _collectionForUser(uid)
        .where('courseId', isEqualTo: courseId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Document.fromFirestore).toList());
  }

  /// Stream of every document owned by [uid], newest first.
  ///
  /// Sorting happens on the client so this collection-wide listener does not
  /// require a new Firestore index and does not omit legacy rows that lack an
  /// `uploadedAt` field.
  Stream<List<Document>> watchAll(String uid) {
    return _collectionForUser(uid).snapshots().map((snap) {
      final documents = snap.docs.map(Document.fromFirestore).toList();
      documents.sort(_newestDocumentFirst);
      return documents;
    });
  }

  /// Watches a single doc — used by the upload flow to flip from extracting → ready.
  Stream<Document?> watchById(String uid, String documentId) {
    return _collectionForUser(uid).doc(documentId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Document.fromFirestore(snap);
    });
  }

  /// Uploads a local file to Firebase Storage and yields progress.
  /// Returns the storage path (e.g. `users/<uid>/documents/<docId>/original.pdf`)
  /// once complete.
  Stream<UploadProgress> uploadFile({
    required File file,
    required String storagePath,
    String? contentType,
  }) async* {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final metadata = SettableMetadata(contentType: contentType);
    final task = ref.putFile(file, metadata);

    await for (final snap in task.snapshotEvents) {
      yield UploadProgress(
        transferred: snap.bytesTransferred,
        total: snap.totalBytes,
      );
      if (snap.state == TaskState.error || snap.state == TaskState.canceled) {
        throw StateError('Upload ${snap.state.name}');
      }
    }
  }

  /// Builds the canonical Storage path for a new document upload.
  /// Sprint 3 generates a Firestore-style 20-char id locally so the path is
  /// stable before the doc actually exists in Firestore. The backend will
  /// later create the Firestore doc with its own id — that's fine, we just
  /// pass the storage path through.
  String buildStoragePath({required String fileExtension}) {
    final docId = _collection().doc().id; // 20-char auto id
    return 'users/${_uid()}/documents/$docId/original$fileExtension';
  }

  Future<Document> createFromFile({
    required String courseId,
    required DocumentSourceType sourceType,
    required String fileName,
    required int fileSize,
    required String storagePath,
    String? mimeType,
    String? title,
  }) async {
    final json =
        await _api.post(
              '/documents',
              body: {
                'courseId': courseId,
                'sourceType': sourceType.toJson(),
                'fileName': fileName,
                'fileSize': fileSize,
                'storagePath': storagePath,
                'mimeType': ?mimeType,
                'title': ?title,
              },
            )
            as Map<String, dynamic>;
    return Document.fromJson(json);
  }

  Future<Document> createFromUrl({
    required String courseId,
    required DocumentSourceType sourceType,
    required String url,
    String? title,
  }) async {
    final json =
        await _api.post(
              '/documents',
              body: {
                'courseId': courseId,
                'sourceType': sourceType.toJson(),
                'sourceUrl': url,
                'title': ?title,
              },
            )
            as Map<String, dynamic>;
    return Document.fromJson(json);
  }

  Future<void> delete(String documentId) async {
    await _api.delete('/documents/$documentId');
  }

  /// Fetches UTF-8 extracted text from Storage.
  ///
  /// An empty object is returned as an empty string. Download failures,
  /// over-limit objects, and malformed UTF-8 are surfaced to the provider as
  /// errors so the UI can distinguish them from legitimately empty content
  /// and offer a retry.
  Future<String?> fetchExtractedText(String extractedTextPath) async {
    try {
      final ref = FirebaseStorage.instance.ref(extractedTextPath);
      // 5 MB cap — extracted text rarely exceeds this and we'd rather error
      // than OOM the device.
      final bytes = await ref.getData(5 * 1024 * 1024);
      if (bytes == null) {
        throw const ExtractedTextLoadException(
          'The extracted text is larger than the 5 MiB viewing limit.',
        );
      }
      return decodeExtractedText(bytes);
    } on ExtractedTextLoadException {
      rethrow;
    } on FormatException catch (error) {
      throw ExtractedTextLoadException(
        'The extracted text is not valid UTF-8.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw ExtractedTextLoadException(
        'Cramly could not download the extracted text.',
        cause: error,
      );
    } catch (error) {
      throw ExtractedTextLoadException(
        'Cramly could not load the extracted text.',
        cause: error,
      );
    }
  }
}

/// Decodes extracted-text bytes without silently replacing malformed input.
String decodeExtractedText(List<int> bytes) => utf8.decode(bytes);

class ExtractedTextLoadException implements Exception {
  const ExtractedTextLoadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

int _newestDocumentFirst(Document a, Document b) {
  final aDate = a.uploadedAt ?? a.extractedAt;
  final bDate = b.uploadedAt ?? b.extractedAt;
  if (aDate == null && bDate == null) return a.id.compareTo(b.id);
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  return byDate == 0 ? a.id.compareTo(b.id) : byDate;
}
