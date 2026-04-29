import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_providers.dart';
import '../data/summary_model.dart';
import '../data/summary_repository.dart';

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(ref.watch(apiClientProvider));
});

final summaryByIdProvider = StreamProvider.family<Summary?, String>((ref, id) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<Summary?>.empty();
  }
  return ref.watch(summaryRepositoryProvider).watchById(user.uid, id);
});
