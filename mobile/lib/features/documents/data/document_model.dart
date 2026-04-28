// ignore_for_file: invalid_annotation_target

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_model.freezed.dart';
part 'document_model.g.dart';

/// Mirrors `users/{uid}/documents/{docId}` per spec §5.1, with two additions:
/// - sourceType: which extractor produced this doc
/// - sourceUrl: the URL for YouTube / web_url sources
enum DocumentSourceType {
  pdf,
  docx,
  pptx,
  image,
  audio,
  youtube,
  webUrl;

  String toJson() => switch (this) {
        DocumentSourceType.webUrl => 'web_url',
        _ => name,
      };

  static DocumentSourceType fromJson(String raw) => switch (raw) {
        'pdf' => DocumentSourceType.pdf,
        'docx' => DocumentSourceType.docx,
        'pptx' => DocumentSourceType.pptx,
        'image' => DocumentSourceType.image,
        'audio' => DocumentSourceType.audio,
        'youtube' => DocumentSourceType.youtube,
        'web_url' => DocumentSourceType.webUrl,
        _ => DocumentSourceType.pdf,
      };
}

enum DocumentStatus {
  uploading,
  extracting,
  ready,
  failed;

  static DocumentStatus fromJson(String raw) => switch (raw) {
        'uploading' => DocumentStatus.uploading,
        'extracting' => DocumentStatus.extracting,
        'ready' => DocumentStatus.ready,
        'failed' => DocumentStatus.failed,
        _ => DocumentStatus.extracting,
      };

  String toJson() => name;
}

@freezed
class GeneratedAssets with _$GeneratedAssets {
  const factory GeneratedAssets({
    @Default([]) List<String> deckIds,
    @Default([]) List<String> quizIds,
    @Default([]) List<String> summaryIds,
    @Default([]) List<String> studyGuideIds,
    @Default([]) List<String> podcastIds,
  }) = _GeneratedAssets;

  factory GeneratedAssets.fromJson(Map<String, dynamic> json) =>
      _$GeneratedAssetsFromJson(json);
}

@freezed
class Document with _$Document {
  const factory Document({
    required String id,
    required String courseId,
    required DocumentSourceType sourceType,
    required String title,
    required DocumentStatus status,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    String? sourceUrl,
    int? pageCount,
    @Default(0) int wordCount,
    String? extractedTextPath,
    String? errorMessage,
    @Default(GeneratedAssets()) GeneratedAssets generatedAssets,
    DateTime? uploadedAt,
    DateTime? extractedAt,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      sourceType:
          DocumentSourceType.fromJson(json['sourceType'] as String? ?? 'pdf'),
      title: json['title'] as String? ?? '',
      status: DocumentStatus.fromJson(json['status'] as String? ?? 'extracting'),
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      storagePath: json['storagePath'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      extractedTextPath: json['extractedTextPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      generatedAssets: json['generatedAssets'] is Map<String, dynamic>
          ? GeneratedAssets.fromJson(
              json['generatedAssets'] as Map<String, dynamic>)
          : const GeneratedAssets(),
      uploadedAt: _parseDate(json['uploadedAt']),
      extractedAt: _parseDate(json['extractedAt']),
    );
  }

  factory Document.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const {};
    return Document(
      id: snap.id,
      courseId: data['courseId'] as String? ?? '',
      sourceType:
          DocumentSourceType.fromJson(data['sourceType'] as String? ?? 'pdf'),
      title: data['title'] as String? ?? '',
      status: DocumentStatus.fromJson(
          data['status'] as String? ?? 'extracting'),
      fileName: data['fileName'] as String?,
      fileSize: (data['fileSize'] as num?)?.toInt(),
      mimeType: data['mimeType'] as String?,
      storagePath: data['storagePath'] as String?,
      sourceUrl: data['sourceUrl'] as String?,
      pageCount: (data['pageCount'] as num?)?.toInt(),
      wordCount: (data['wordCount'] as num?)?.toInt() ?? 0,
      extractedTextPath: data['extractedTextPath'] as String?,
      errorMessage: data['errorMessage'] as String?,
      generatedAssets: data['generatedAssets'] is Map<String, dynamic>
          ? GeneratedAssets.fromJson(
              Map<String, dynamic>.from(data['generatedAssets'] as Map))
          : const GeneratedAssets(),
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
      extractedAt: (data['extractedAt'] as Timestamp?)?.toDate(),
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is Timestamp) return raw.toDate();
  return null;
}
