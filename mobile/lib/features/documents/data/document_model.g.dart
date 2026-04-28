// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GeneratedAssetsImpl _$$GeneratedAssetsImplFromJson(
  Map<String, dynamic> json,
) => _$GeneratedAssetsImpl(
  deckIds:
      (json['deckIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  quizIds:
      (json['quizIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  summaryIds:
      (json['summaryIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  studyGuideIds:
      (json['studyGuideIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  podcastIds:
      (json['podcastIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$GeneratedAssetsImplToJson(
  _$GeneratedAssetsImpl instance,
) => <String, dynamic>{
  'deckIds': instance.deckIds,
  'quizIds': instance.quizIds,
  'summaryIds': instance.summaryIds,
  'studyGuideIds': instance.studyGuideIds,
  'podcastIds': instance.podcastIds,
};
