// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Course _$CourseFromJson(Map<String, dynamic> json) {
  return _Course.fromJson(json);
}

/// @nodoc
mixin _$Course {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;
  int get documentCount => throw _privateConstructorUsedError;
  int get deckCount => throw _privateConstructorUsedError;
  int get quizCount => throw _privateConstructorUsedError;
  @JsonKey(toJson: _ts, fromJson: _tsFrom)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(toJson: _ts, fromJson: _tsFrom)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Course to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CourseCopyWith<Course> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseCopyWith<$Res> {
  factory $CourseCopyWith(Course value, $Res Function(Course) then) =
      _$CourseCopyWithImpl<$Res, Course>;
  @useResult
  $Res call({
    String id,
    String name,
    String color,
    String? icon,
    int documentCount,
    int deckCount,
    int quizCount,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) DateTime? createdAt,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) DateTime? updatedAt,
  });
}

/// @nodoc
class _$CourseCopyWithImpl<$Res, $Val extends Course>
    implements $CourseCopyWith<$Res> {
  _$CourseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? icon = freezed,
    Object? documentCount = null,
    Object? deckCount = null,
    Object? quizCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: freezed == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String?,
            documentCount: null == documentCount
                ? _value.documentCount
                : documentCount // ignore: cast_nullable_to_non_nullable
                      as int,
            deckCount: null == deckCount
                ? _value.deckCount
                : deckCount // ignore: cast_nullable_to_non_nullable
                      as int,
            quizCount: null == quizCount
                ? _value.quizCount
                : quizCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CourseImplCopyWith<$Res> implements $CourseCopyWith<$Res> {
  factory _$$CourseImplCopyWith(
    _$CourseImpl value,
    $Res Function(_$CourseImpl) then,
  ) = __$$CourseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String color,
    String? icon,
    int documentCount,
    int deckCount,
    int quizCount,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) DateTime? createdAt,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CourseImplCopyWithImpl<$Res>
    extends _$CourseCopyWithImpl<$Res, _$CourseImpl>
    implements _$$CourseImplCopyWith<$Res> {
  __$$CourseImplCopyWithImpl(
    _$CourseImpl _value,
    $Res Function(_$CourseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? icon = freezed,
    Object? documentCount = null,
    Object? deckCount = null,
    Object? quizCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CourseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: freezed == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String?,
        documentCount: null == documentCount
            ? _value.documentCount
            : documentCount // ignore: cast_nullable_to_non_nullable
                  as int,
        deckCount: null == deckCount
            ? _value.deckCount
            : deckCount // ignore: cast_nullable_to_non_nullable
                  as int,
        quizCount: null == quizCount
            ? _value.quizCount
            : quizCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseImpl implements _Course {
  const _$CourseImpl({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.documentCount = 0,
    this.deckCount = 0,
    this.quizCount = 0,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) this.createdAt,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) this.updatedAt,
  });

  factory _$CourseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String color;
  @override
  final String? icon;
  @override
  @JsonKey()
  final int documentCount;
  @override
  @JsonKey()
  final int deckCount;
  @override
  @JsonKey()
  final int quizCount;
  @override
  @JsonKey(toJson: _ts, fromJson: _tsFrom)
  final DateTime? createdAt;
  @override
  @JsonKey(toJson: _ts, fromJson: _tsFrom)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Course(id: $id, name: $name, color: $color, icon: $icon, documentCount: $documentCount, deckCount: $deckCount, quizCount: $quizCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.documentCount, documentCount) ||
                other.documentCount == documentCount) &&
            (identical(other.deckCount, deckCount) ||
                other.deckCount == deckCount) &&
            (identical(other.quizCount, quizCount) ||
                other.quizCount == quizCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    color,
    icon,
    documentCount,
    deckCount,
    quizCount,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseImplCopyWith<_$CourseImpl> get copyWith =>
      __$$CourseImplCopyWithImpl<_$CourseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseImplToJson(this);
  }
}

abstract class _Course implements Course {
  const factory _Course({
    required final String id,
    required final String name,
    required final String color,
    final String? icon,
    final int documentCount,
    final int deckCount,
    final int quizCount,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) final DateTime? createdAt,
    @JsonKey(toJson: _ts, fromJson: _tsFrom) final DateTime? updatedAt,
  }) = _$CourseImpl;

  factory _Course.fromJson(Map<String, dynamic> json) = _$CourseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get color;
  @override
  String? get icon;
  @override
  int get documentCount;
  @override
  int get deckCount;
  @override
  int get quizCount;
  @override
  @JsonKey(toJson: _ts, fromJson: _tsFrom)
  DateTime? get createdAt;
  @override
  @JsonKey(toJson: _ts, fromJson: _tsFrom)
  DateTime? get updatedAt;

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CourseImplCopyWith<_$CourseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
