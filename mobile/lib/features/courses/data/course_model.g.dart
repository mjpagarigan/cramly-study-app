// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourseImpl _$$CourseImplFromJson(Map<String, dynamic> json) => _$CourseImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  color: json['color'] as String,
  icon: json['icon'] as String?,
  documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
  deckCount: (json['deckCount'] as num?)?.toInt() ?? 0,
  quizCount: (json['quizCount'] as num?)?.toInt() ?? 0,
  createdAt: _tsFrom(json['createdAt']),
  updatedAt: _tsFrom(json['updatedAt']),
);

Map<String, dynamic> _$$CourseImplToJson(_$CourseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
      'documentCount': instance.documentCount,
      'deckCount': instance.deckCount,
      'quizCount': instance.quizCount,
      'createdAt': _ts(instance.createdAt),
      'updatedAt': _ts(instance.updatedAt),
    };
