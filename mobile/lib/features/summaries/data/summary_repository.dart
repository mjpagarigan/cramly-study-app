import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/api/api_client.dart';
import 'summary_model.dart';

class SummaryRepository {
  SummaryRepository(this._api);

  final ApiClient _api;

  CollectionReference<Map<String, dynamic>> _collectionForUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('summaries');
  }

  Stream<Summary?> watchById(String uid, String summaryId) {
    return _collectionForUser(uid).doc(summaryId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Summary.fromFirestore(snap);
    });
  }

  /// Watches every summary owned by [uid], newest first. Client-side sorting
  /// avoids adding an index and keeps rows without `updatedAt` available.
  Stream<List<Summary>> watchAll(String uid) {
    return _collectionForUser(uid).snapshots().map((snap) {
      final summaries = snap.docs.map(Summary.fromFirestore).toList();
      summaries.sort(_newestSummaryFirst);
      return summaries;
    });
  }

  Future<SummaryGenerationResult> generateSummary({
    required String documentId,
    required SummaryDepth depth,
  }) async {
    final json =
        await _api.post(
              '/documents/$documentId/generate',
              body: {'generator': 'summary', 'depth': depth.toJson()},
            )
            as Map<String, dynamic>;
    return SummaryGenerationResult.fromJson(json);
  }
}

int _newestSummaryFirst(Summary a, Summary b) {
  final aDate = a.updatedAt ?? a.createdAt;
  final bDate = b.updatedAt ?? b.createdAt;
  if (aDate == null && bDate == null) return a.id.compareTo(b.id);
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  return byDate == 0 ? a.id.compareTo(b.id) : byDate;
}
