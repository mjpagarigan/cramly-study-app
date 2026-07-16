import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/async_job_model.dart';
import '../data/async_job_repository.dart';

final asyncJobRepositoryProvider = Provider<AsyncJobRepository>((ref) {
  return AsyncJobRepository();
});

final asyncJobByIdProvider = StreamProvider.autoDispose
    .family<AsyncJob?, String>((ref, jobId) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream<AsyncJob?>.empty();
      }
      return ref.watch(asyncJobRepositoryProvider).watchById(user.uid, jobId);
    });
