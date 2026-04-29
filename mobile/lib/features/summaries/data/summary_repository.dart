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

  Future<SummaryGenerationResult> generateSummary({
    required String documentId,
    required SummaryDepth depth,
  }) async {
    final json = await _api.post('/documents/$documentId/generate', body: {
      'generator': 'summary',
      'depth': depth.toJson(),
    }) as Map<String, dynamic>;
    return SummaryGenerationResult.fromJson(json);
  }
}
