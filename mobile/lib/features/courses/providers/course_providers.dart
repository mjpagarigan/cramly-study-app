import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/course_model.dart';
import '../data/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(apiClientProvider));
});

/// Real-time list of the signed-in user's courses, ordered by `updatedAt desc`.
final coursesStreamProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).watchCourses();
});

/// Picks a single course out of the stream by id (used by the detail screen).
final courseByIdProvider = Provider.family<Course?, String>((ref, id) {
  final list = ref.watch(coursesStreamProvider).valueOrNull ?? [];
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

class CourseController extends StateNotifier<AsyncValue<void>> {
  CourseController(this._repo) : super(const AsyncValue.data(null));
  final CourseRepository _repo;

  Future<Course?> create({
    required String name,
    required String color,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final course = await _repo.create(name: name, color: color, icon: icon);
      state = const AsyncValue.data(null);
      return course;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Course?> update(
    String id, {
    String? name,
    String? color,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final course =
          await _repo.update(id, name: name, color: color, icon: icon);
      state = const AsyncValue.data(null);
      return course;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.delete(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final courseControllerProvider =
    StateNotifierProvider<CourseController, AsyncValue<void>>((ref) {
  return CourseController(ref.watch(courseRepositoryProvider));
});
