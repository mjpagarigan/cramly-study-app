import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/api/api_client.dart';
import 'course_model.dart';

/// Reads use a real-time Firestore listener (offline cache + auto-refresh).
/// Writes go through FastAPI so the server can stamp timestamps, validate, and
/// (eventually) cascade-delete child resources.
class CourseRepository {
  CourseRepository(this._api);

  final ApiClient _api;

  CollectionReference<Map<String, dynamic>> _coursesCollection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('courses');
  }

  Stream<List<Course>> watchCourses(String uid) {
    return _coursesCollection(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromFirestore).toList());
  }

  Future<Course> create({
    required String name,
    required String color,
    String? icon,
  }) async {
    final json = await _api.post('/courses', body: {
      'name': name,
      'color': color,
      'icon': ?icon,
    }) as Map<String, dynamic>;
    return Course.fromJson(json);
  }

  Future<Course> update(
    String id, {
    String? name,
    String? color,
    String? icon,
  }) async {
    final json = await _api.patch('/courses/$id', body: {
      'name': ?name,
      'color': ?color,
      'icon': ?icon,
    }) as Map<String, dynamic>;
    return Course.fromJson(json);
  }

  Future<void> delete(String id) async {
    await _api.delete('/courses/$id');
  }
}
