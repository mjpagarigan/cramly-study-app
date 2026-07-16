import 'package:cloud_firestore/cloud_firestore.dart';

enum AsyncJobStatus {
  queued,
  processing,
  completed,
  failed;

  static AsyncJobStatus fromJson(String raw) => switch (raw) {
    'queued' => AsyncJobStatus.queued,
    'processing' => AsyncJobStatus.processing,
    'completed' => AsyncJobStatus.completed,
    'failed' => AsyncJobStatus.failed,
    _ => AsyncJobStatus.queued,
  };
}

class AsyncJob {
  const AsyncJob({
    required this.id,
    required this.type,
    required this.status,
    required this.progress,
    this.errorMessage,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String type;
  final AsyncJobStatus status;
  final int progress;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory AsyncJob.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return AsyncJob(
      id: snap.id,
      type: data['type'] as String? ?? '',
      status: AsyncJobStatus.fromJson(data['status'] as String? ?? 'queued'),
      progress: (data['progress'] as num?)?.toInt() ?? 0,
      errorMessage: data['errorMessage'] as String?,
      createdAt: _parseDate(data['createdAt']),
      startedAt: _parseDate(data['startedAt']),
      completedAt: _parseDate(data['completedAt']),
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is Timestamp) return raw.toDate();
  return null;
}
