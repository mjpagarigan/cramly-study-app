import 'package:cloud_firestore/cloud_firestore.dart';

enum DeckGenerationMethod {
  ai,
  manual;

  static DeckGenerationMethod fromJson(String raw) => switch (raw) {
    'ai' => DeckGenerationMethod.ai,
    'manual' => DeckGenerationMethod.manual,
    _ => DeckGenerationMethod.manual,
  };

  String get label => switch (this) {
    DeckGenerationMethod.ai => 'AI',
    DeckGenerationMethod.manual => 'Manual',
  };
}

enum DeckStatus {
  queued,
  generating,
  ready,
  failed;

  static DeckStatus fromJson(String raw) => switch (raw) {
    'queued' => DeckStatus.queued,
    'generating' => DeckStatus.generating,
    'ready' => DeckStatus.ready,
    'failed' => DeckStatus.failed,
    _ => DeckStatus.ready,
  };

  String get label => switch (this) {
    DeckStatus.queued => 'Queued',
    DeckStatus.generating => 'Generating',
    DeckStatus.ready => 'Ready',
    DeckStatus.failed => 'Failed',
  };

  bool get isPending =>
      this == DeckStatus.queued || this == DeckStatus.generating;
}

class DeckCardItem {
  const DeckCardItem({
    required this.id,
    required this.front,
    required this.back,
    this.hint,
    this.explanation,
    this.topic,
    this.createdAt,
  });

  final String id;
  final String front;
  final String back;
  final String? hint;
  final String? explanation;
  final String? topic;
  final DateTime? createdAt;

  factory DeckCardItem.fromJson(Map<String, dynamic> json) {
    return DeckCardItem(
      id: json['id'] as String? ?? '',
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      hint: json['hint'] as String?,
      explanation: json['explanation'] as String?,
      topic: json['topic'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  factory DeckCardItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const {};
    return DeckCardItem(
      id: snap.id,
      front: data['front'] as String? ?? '',
      back: data['back'] as String? ?? '',
      hint: data['hint'] as String?,
      explanation: data['explanation'] as String?,
      topic: data['topic'] as String?,
      createdAt: _parseDate(data['createdAt']),
    );
  }
}

class Deck {
  const Deck({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.cardCount,
    required this.generationMethod,
    required this.status,
    this.sourceDocumentId,
    this.jobId,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final int cardCount;
  final DeckGenerationMethod generationMethod;
  final DeckStatus status;
  final String? sourceDocumentId;
  final String? jobId;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
      generationMethod: DeckGenerationMethod.fromJson(
        json['generationMethod'] as String? ?? 'manual',
      ),
      status: DeckStatus.fromJson(json['status'] as String? ?? 'ready'),
      sourceDocumentId: json['sourceDocumentId'] as String?,
      jobId: json['jobId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  factory Deck.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return Deck(
      id: snap.id,
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      cardCount: (data['cardCount'] as num?)?.toInt() ?? 0,
      generationMethod: DeckGenerationMethod.fromJson(
        data['generationMethod'] as String? ?? 'manual',
      ),
      status: DeckStatus.fromJson(data['status'] as String? ?? 'ready'),
      sourceDocumentId: data['sourceDocumentId'] as String?,
      jobId: data['jobId'] as String?,
      errorMessage: data['errorMessage'] as String?,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }
}

class DeckGenerationResult {
  const DeckGenerationResult({required this.deck, required this.jobId});

  final Deck deck;
  final String jobId;

  factory DeckGenerationResult.fromJson(Map<String, dynamic> json) {
    final deck = Deck.fromJson(
      Map<String, dynamic>.from(json['deck'] as Map? ?? const {}),
    );
    final job = Map<String, dynamic>.from(json['job'] as Map? ?? const {});
    return DeckGenerationResult(
      deck: deck,
      jobId: job['id'] as String? ?? deck.jobId ?? '',
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is Timestamp) return raw.toDate();
  return null;
}
