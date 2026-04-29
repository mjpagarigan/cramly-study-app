import 'package:cloud_firestore/cloud_firestore.dart';

import 'async_job_model.dart';

class AsyncJobRepository {
  CollectionReference<Map<String, dynamic>> _collectionForUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('asyncJobs');
  }

  Stream<AsyncJob?> watchById(String uid, String jobId) {
    return _collectionForUser(uid).doc(jobId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AsyncJob.fromFirestore(snap);
    });
  }
}
