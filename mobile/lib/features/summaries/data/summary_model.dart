import 'package:cloud_firestore/cloud_firestore.dart';

enum SummaryDepth {
  tldr,
  detailed,
  eli5;

  String toJson() => name;

  String get label => switch (this) {
        SummaryDepth.tldr => 'TL;DR',
        SummaryDepth.detailed => 'Detailed',
        SummaryDepth.eli5 => 'ELI5',
      };

  String get description => switch (this) {
        SummaryDepth.tldr => 'Fast recap with only the biggest takeaways.',
        SummaryDepth.detailed => 'Structured notes with more supporting detail.',
        SummaryDepth.eli5 => 'Simpler language for quick understanding.',
      };

  static SummaryDepth fromJson(String raw) => switch (raw) {
        'tldr' => SummaryDepth.tldr,
        'detailed' => SummaryDepth.detailed,
        'eli5' => SummaryDepth.eli5,
        _ => SummaryDepth.detailed,
      };
}

enum SummaryStatus {
  queued,
  generating,
  ready,
  failed;

  static SummaryStatus fromJson(String raw) => switch (raw) {
        'queued' => SummaryStatus.queued,
        'generating' => SummaryStatus.generating,
        'ready' => SummaryStatus.ready,
        'failed' => SummaryStatus.failed,
        _ => SummaryStatus.queued,
      };
}

class Summary {
  const Summary({
    required this.id,
    required this.courseId,
    required this.sourceDocumentId,
    required this.depth,
    required this.status,
    required this.content,
    this.jobId,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseId;
  final String sourceDocumentId;
  final SummaryDepth depth;
  final SummaryStatus status;
  final String content;
  final String? jobId;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      sourceDocumentId: json['sourceDocumentId'] as String? ?? '',
      depth: SummaryDepth.fromJson(json['depth'] as String? ?? 'detailed'),
      status: SummaryStatus.fromJson(json['status'] as String? ?? 'queued'),
      content: json['content'] as String? ?? '',
      jobId: json['jobId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  factory Summary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const {};
    return Summary(
      id: snap.id,
      courseId: data['courseId'] as String? ?? '',
      sourceDocumentId: data['sourceDocumentId'] as String? ?? '',
      depth: SummaryDepth.fromJson(data['depth'] as String? ?? 'detailed'),
      status: SummaryStatus.fromJson(data['status'] as String? ?? 'queued'),
      content: data['content'] as String? ?? '',
      jobId: data['jobId'] as String?,
      errorMessage: data['errorMessage'] as String?,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }
}

class SummaryGenerationResult {
  const SummaryGenerationResult({
    required this.summary,
    required this.jobId,
  });

  final Summary summary;
  final String jobId;

  factory SummaryGenerationResult.fromJson(Map<String, dynamic> json) {
    final summary = Summary.fromJson(
      Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
    );
    final job = Map<String, dynamic>.from(json['job'] as Map? ?? const {});
    return SummaryGenerationResult(
      summary: summary,
      jobId: job['id'] as String? ?? summary.jobId ?? '',
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is Timestamp) return raw.toDate();
  return null;
}
