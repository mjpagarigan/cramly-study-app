// JsonKey on freezed factory params is the standard pattern for custom
// (de)serialization, but the analyzer flags it as `invalid_annotation_target`.
// Suppressed file-wide per the freezed maintainers' recommendation.
// ignore_for_file: invalid_annotation_target

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_model.freezed.dart';
part 'course_model.g.dart';

/// Mirrors `users/{uid}/courses/{courseId}` in Firestore.
/// Spec §5.1: name, color, icon, denormalized counts, timestamps.
@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String name,
    required String color,
    String? icon,
    @Default(0) int documentCount,
    @Default(0) int deckCount,
    @Default(0) int quizCount,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) DateTime? createdAt,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) DateTime? updatedAt,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  factory Course.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return Course(
      id: snap.id,
      name: data['name'] as String? ?? '',
      color: data['color'] as String? ?? '#477966',
      icon: data['icon'] as String?,
      documentCount: (data['documentCount'] as num?)?.toInt() ?? 0,
      deckCount: (data['deckCount'] as num?)?.toInt() ?? 0,
      quizCount: (data['quizCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

dynamic _ts(DateTime? d) => d?.toIso8601String();
DateTime? _tsFrom(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is Timestamp) return v.toDate();
  return null;
}
