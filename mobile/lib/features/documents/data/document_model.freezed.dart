// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GeneratedAssets _$GeneratedAssetsFromJson(Map<String, dynamic> json) {
  return _GeneratedAssets.fromJson(json);
}

/// @nodoc
mixin _$GeneratedAssets {
  List<String> get deckIds => throw _privateConstructorUsedError;
  List<String> get quizIds => throw _privateConstructorUsedError;
  List<String> get summaryIds => throw _privateConstructorUsedError;
  List<String> get studyGuideIds => throw _privateConstructorUsedError;
  List<String> get podcastIds => throw _privateConstructorUsedError;

  /// Serializes this GeneratedAssets to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GeneratedAssets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GeneratedAssetsCopyWith<GeneratedAssets> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeneratedAssetsCopyWith<$Res> {
  factory $GeneratedAssetsCopyWith(
    GeneratedAssets value,
    $Res Function(GeneratedAssets) then,
  ) = _$GeneratedAssetsCopyWithImpl<$Res, GeneratedAssets>;
  @useResult
  $Res call({
    List<String> deckIds,
    List<String> quizIds,
    List<String> summaryIds,
    List<String> studyGuideIds,
    List<String> podcastIds,
  });
}

/// @nodoc
class _$GeneratedAssetsCopyWithImpl<$Res, $Val extends GeneratedAssets>
    implements $GeneratedAssetsCopyWith<$Res> {
  _$GeneratedAssetsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GeneratedAssets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deckIds = null,
    Object? quizIds = null,
    Object? summaryIds = null,
    Object? studyGuideIds = null,
    Object? podcastIds = null,
  }) {
    return _then(
      _value.copyWith(
            deckIds: null == deckIds
                ? _value.deckIds
                : deckIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            quizIds: null == quizIds
                ? _value.quizIds
                : quizIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            summaryIds: null == summaryIds
                ? _value.summaryIds
                : summaryIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            studyGuideIds: null == studyGuideIds
                ? _value.studyGuideIds
                : studyGuideIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            podcastIds: null == podcastIds
                ? _value.podcastIds
                : podcastIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GeneratedAssetsImplCopyWith<$Res>
    implements $GeneratedAssetsCopyWith<$Res> {
  factory _$$GeneratedAssetsImplCopyWith(
    _$GeneratedAssetsImpl value,
    $Res Function(_$GeneratedAssetsImpl) then,
  ) = __$$GeneratedAssetsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> deckIds,
    List<String> quizIds,
    List<String> summaryIds,
    List<String> studyGuideIds,
    List<String> podcastIds,
  });
}

/// @nodoc
class __$$GeneratedAssetsImplCopyWithImpl<$Res>
    extends _$GeneratedAssetsCopyWithImpl<$Res, _$GeneratedAssetsImpl>
    implements _$$GeneratedAssetsImplCopyWith<$Res> {
  __$$GeneratedAssetsImplCopyWithImpl(
    _$GeneratedAssetsImpl _value,
    $Res Function(_$GeneratedAssetsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GeneratedAssets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deckIds = null,
    Object? quizIds = null,
    Object? summaryIds = null,
    Object? studyGuideIds = null,
    Object? podcastIds = null,
  }) {
    return _then(
      _$GeneratedAssetsImpl(
        deckIds: null == deckIds
            ? _value._deckIds
            : deckIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        quizIds: null == quizIds
            ? _value._quizIds
            : quizIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        summaryIds: null == summaryIds
            ? _value._summaryIds
            : summaryIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        studyGuideIds: null == studyGuideIds
            ? _value._studyGuideIds
            : studyGuideIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        podcastIds: null == podcastIds
            ? _value._podcastIds
            : podcastIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GeneratedAssetsImpl implements _GeneratedAssets {
  const _$GeneratedAssetsImpl({
    final List<String> deckIds = const [],
    final List<String> quizIds = const [],
    final List<String> summaryIds = const [],
    final List<String> studyGuideIds = const [],
    final List<String> podcastIds = const [],
  }) : _deckIds = deckIds,
       _quizIds = quizIds,
       _summaryIds = summaryIds,
       _studyGuideIds = studyGuideIds,
       _podcastIds = podcastIds;

  factory _$GeneratedAssetsImpl.fromJson(Map<String, dynamic> json) =>
      _$$GeneratedAssetsImplFromJson(json);

  final List<String> _deckIds;
  @override
  @JsonKey()
  List<String> get deckIds {
    if (_deckIds is EqualUnmodifiableListView) return _deckIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deckIds);
  }

  final List<String> _quizIds;
  @override
  @JsonKey()
  List<String> get quizIds {
    if (_quizIds is EqualUnmodifiableListView) return _quizIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quizIds);
  }

  final List<String> _summaryIds;
  @override
  @JsonKey()
  List<String> get summaryIds {
    if (_summaryIds is EqualUnmodifiableListView) return _summaryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_summaryIds);
  }

  final List<String> _studyGuideIds;
  @override
  @JsonKey()
  List<String> get studyGuideIds {
    if (_studyGuideIds is EqualUnmodifiableListView) return _studyGuideIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_studyGuideIds);
  }

  final List<String> _podcastIds;
  @override
  @JsonKey()
  List<String> get podcastIds {
    if (_podcastIds is EqualUnmodifiableListView) return _podcastIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_podcastIds);
  }

  @override
  String toString() {
    return 'GeneratedAssets(deckIds: $deckIds, quizIds: $quizIds, summaryIds: $summaryIds, studyGuideIds: $studyGuideIds, podcastIds: $podcastIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeneratedAssetsImpl &&
            const DeepCollectionEquality().equals(other._deckIds, _deckIds) &&
            const DeepCollectionEquality().equals(other._quizIds, _quizIds) &&
            const DeepCollectionEquality().equals(
              other._summaryIds,
              _summaryIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._studyGuideIds,
              _studyGuideIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._podcastIds,
              _podcastIds,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_deckIds),
    const DeepCollectionEquality().hash(_quizIds),
    const DeepCollectionEquality().hash(_summaryIds),
    const DeepCollectionEquality().hash(_studyGuideIds),
    const DeepCollectionEquality().hash(_podcastIds),
  );

  /// Create a copy of GeneratedAssets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GeneratedAssetsImplCopyWith<_$GeneratedAssetsImpl> get copyWith =>
      __$$GeneratedAssetsImplCopyWithImpl<_$GeneratedAssetsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GeneratedAssetsImplToJson(this);
  }
}

abstract class _GeneratedAssets implements GeneratedAssets {
  const factory _GeneratedAssets({
    final List<String> deckIds,
    final List<String> quizIds,
    final List<String> summaryIds,
    final List<String> studyGuideIds,
    final List<String> podcastIds,
  }) = _$GeneratedAssetsImpl;

  factory _GeneratedAssets.fromJson(Map<String, dynamic> json) =
      _$GeneratedAssetsImpl.fromJson;

  @override
  List<String> get deckIds;
  @override
  List<String> get quizIds;
  @override
  List<String> get summaryIds;
  @override
  List<String> get studyGuideIds;
  @override
  List<String> get podcastIds;

  /// Create a copy of GeneratedAssets
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GeneratedAssetsImplCopyWith<_$GeneratedAssetsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Document {
  String get id => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  DocumentSourceType get sourceType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DocumentStatus get status => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  String? get mimeType => throw _privateConstructorUsedError;
  String? get storagePath => throw _privateConstructorUsedError;
  String? get sourceUrl => throw _privateConstructorUsedError;
  int? get pageCount => throw _privateConstructorUsedError;
  int get wordCount => throw _privateConstructorUsedError;
  String? get extractedTextPath => throw _privateConstructorUsedError;
  String? get extractionJobId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  GeneratedAssets get generatedAssets => throw _privateConstructorUsedError;
  DateTime? get uploadedAt => throw _privateConstructorUsedError;
  DateTime? get extractedAt => throw _privateConstructorUsedError;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentCopyWith<Document> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentCopyWith<$Res> {
  factory $DocumentCopyWith(Document value, $Res Function(Document) then) =
      _$DocumentCopyWithImpl<$Res, Document>;
  @useResult
  $Res call({
    String id,
    String courseId,
    DocumentSourceType sourceType,
    String title,
    DocumentStatus status,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    String? sourceUrl,
    int? pageCount,
    int wordCount,
    String? extractedTextPath,
    String? extractionJobId,
    String? errorMessage,
    GeneratedAssets generatedAssets,
    DateTime? uploadedAt,
    DateTime? extractedAt,
  });

  $GeneratedAssetsCopyWith<$Res> get generatedAssets;
}

/// @nodoc
class _$DocumentCopyWithImpl<$Res, $Val extends Document>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? sourceType = null,
    Object? title = null,
    Object? status = null,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
    Object? storagePath = freezed,
    Object? sourceUrl = freezed,
    Object? pageCount = freezed,
    Object? wordCount = null,
    Object? extractedTextPath = freezed,
    Object? extractionJobId = freezed,
    Object? errorMessage = freezed,
    Object? generatedAssets = null,
    Object? uploadedAt = freezed,
    Object? extractedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            courseId: null == courseId
                ? _value.courseId
                : courseId // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceType: null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                      as DocumentSourceType,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as DocumentStatus,
            fileName: freezed == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileSize: freezed == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            mimeType: freezed == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String?,
            storagePath: freezed == storagePath
                ? _value.storagePath
                : storagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            sourceUrl: freezed == sourceUrl
                ? _value.sourceUrl
                : sourceUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            pageCount: freezed == pageCount
                ? _value.pageCount
                : pageCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            wordCount: null == wordCount
                ? _value.wordCount
                : wordCount // ignore: cast_nullable_to_non_nullable
                      as int,
            extractedTextPath: freezed == extractedTextPath
                ? _value.extractedTextPath
                : extractedTextPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            extractionJobId: freezed == extractionJobId
                ? _value.extractionJobId
                : extractionJobId // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            generatedAssets: null == generatedAssets
                ? _value.generatedAssets
                : generatedAssets // ignore: cast_nullable_to_non_nullable
                      as GeneratedAssets,
            uploadedAt: freezed == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            extractedAt: freezed == extractedAt
                ? _value.extractedAt
                : extractedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GeneratedAssetsCopyWith<$Res> get generatedAssets {
    return $GeneratedAssetsCopyWith<$Res>(_value.generatedAssets, (value) {
      return _then(_value.copyWith(generatedAssets: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DocumentImplCopyWith<$Res>
    implements $DocumentCopyWith<$Res> {
  factory _$$DocumentImplCopyWith(
    _$DocumentImpl value,
    $Res Function(_$DocumentImpl) then,
  ) = __$$DocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String courseId,
    DocumentSourceType sourceType,
    String title,
    DocumentStatus status,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    String? sourceUrl,
    int? pageCount,
    int wordCount,
    String? extractedTextPath,
    String? extractionJobId,
    String? errorMessage,
    GeneratedAssets generatedAssets,
    DateTime? uploadedAt,
    DateTime? extractedAt,
  });

  @override
  $GeneratedAssetsCopyWith<$Res> get generatedAssets;
}

/// @nodoc
class __$$DocumentImplCopyWithImpl<$Res>
    extends _$DocumentCopyWithImpl<$Res, _$DocumentImpl>
    implements _$$DocumentImplCopyWith<$Res> {
  __$$DocumentImplCopyWithImpl(
    _$DocumentImpl _value,
    $Res Function(_$DocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? sourceType = null,
    Object? title = null,
    Object? status = null,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
    Object? storagePath = freezed,
    Object? sourceUrl = freezed,
    Object? pageCount = freezed,
    Object? wordCount = null,
    Object? extractedTextPath = freezed,
    Object? extractionJobId = freezed,
    Object? errorMessage = freezed,
    Object? generatedAssets = null,
    Object? uploadedAt = freezed,
    Object? extractedAt = freezed,
  }) {
    return _then(
      _$DocumentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        courseId: null == courseId
            ? _value.courseId
            : courseId // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceType: null == sourceType
            ? _value.sourceType
            : sourceType // ignore: cast_nullable_to_non_nullable
                  as DocumentSourceType,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DocumentStatus,
        fileName: freezed == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileSize: freezed == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        mimeType: freezed == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String?,
        storagePath: freezed == storagePath
            ? _value.storagePath
            : storagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        sourceUrl: freezed == sourceUrl
            ? _value.sourceUrl
            : sourceUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        pageCount: freezed == pageCount
            ? _value.pageCount
            : pageCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        wordCount: null == wordCount
            ? _value.wordCount
            : wordCount // ignore: cast_nullable_to_non_nullable
                  as int,
        extractedTextPath: freezed == extractedTextPath
            ? _value.extractedTextPath
            : extractedTextPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        extractionJobId: freezed == extractionJobId
            ? _value.extractionJobId
            : extractionJobId // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        generatedAssets: null == generatedAssets
            ? _value.generatedAssets
            : generatedAssets // ignore: cast_nullable_to_non_nullable
                  as GeneratedAssets,
        uploadedAt: freezed == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        extractedAt: freezed == extractedAt
            ? _value.extractedAt
            : extractedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$DocumentImpl implements _Document {
  const _$DocumentImpl({
    required this.id,
    required this.courseId,
    required this.sourceType,
    required this.title,
    required this.status,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.storagePath,
    this.sourceUrl,
    this.pageCount,
    this.wordCount = 0,
    this.extractedTextPath,
    this.extractionJobId,
    this.errorMessage,
    this.generatedAssets = const GeneratedAssets(),
    this.uploadedAt,
    this.extractedAt,
  });

  @override
  final String id;
  @override
  final String courseId;
  @override
  final DocumentSourceType sourceType;
  @override
  final String title;
  @override
  final DocumentStatus status;
  @override
  final String? fileName;
  @override
  final int? fileSize;
  @override
  final String? mimeType;
  @override
  final String? storagePath;
  @override
  final String? sourceUrl;
  @override
  final int? pageCount;
  @override
  @JsonKey()
  final int wordCount;
  @override
  final String? extractedTextPath;
  @override
  final String? extractionJobId;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final GeneratedAssets generatedAssets;
  @override
  final DateTime? uploadedAt;
  @override
  final DateTime? extractedAt;

  @override
  String toString() {
    return 'Document(id: $id, courseId: $courseId, sourceType: $sourceType, title: $title, status: $status, fileName: $fileName, fileSize: $fileSize, mimeType: $mimeType, storagePath: $storagePath, sourceUrl: $sourceUrl, pageCount: $pageCount, wordCount: $wordCount, extractedTextPath: $extractedTextPath, extractionJobId: $extractionJobId, errorMessage: $errorMessage, generatedAssets: $generatedAssets, uploadedAt: $uploadedAt, extractedAt: $extractedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.pageCount, pageCount) ||
                other.pageCount == pageCount) &&
            (identical(other.wordCount, wordCount) ||
                other.wordCount == wordCount) &&
            (identical(other.extractedTextPath, extractedTextPath) ||
                other.extractedTextPath == extractedTextPath) &&
            (identical(other.extractionJobId, extractionJobId) ||
                other.extractionJobId == extractionJobId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.generatedAssets, generatedAssets) ||
                other.generatedAssets == generatedAssets) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.extractedAt, extractedAt) ||
                other.extractedAt == extractedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    courseId,
    sourceType,
    title,
    status,
    fileName,
    fileSize,
    mimeType,
    storagePath,
    sourceUrl,
    pageCount,
    wordCount,
    extractedTextPath,
    extractionJobId,
    errorMessage,
    generatedAssets,
    uploadedAt,
    extractedAt,
  );

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentImplCopyWith<_$DocumentImpl> get copyWith =>
      __$$DocumentImplCopyWithImpl<_$DocumentImpl>(this, _$identity);
}

abstract class _Document implements Document {
  const factory _Document({
    required final String id,
    required final String courseId,
    required final DocumentSourceType sourceType,
    required final String title,
    required final DocumentStatus status,
    final String? fileName,
    final int? fileSize,
    final String? mimeType,
    final String? storagePath,
    final String? sourceUrl,
    final int? pageCount,
    final int wordCount,
    final String? extractedTextPath,
    final String? extractionJobId,
    final String? errorMessage,
    final GeneratedAssets generatedAssets,
    final DateTime? uploadedAt,
    final DateTime? extractedAt,
  }) = _$DocumentImpl;

  @override
  String get id;
  @override
  String get courseId;
  @override
  DocumentSourceType get sourceType;
  @override
  String get title;
  @override
  DocumentStatus get status;
  @override
  String? get fileName;
  @override
  int? get fileSize;
  @override
  String? get mimeType;
  @override
  String? get storagePath;
  @override
  String? get sourceUrl;
  @override
  int? get pageCount;
  @override
  int get wordCount;
  @override
  String? get extractedTextPath;
  @override
  String? get extractionJobId;
  @override
  String? get errorMessage;
  @override
  GeneratedAssets get generatedAssets;
  @override
  DateTime? get uploadedAt;
  @override
  DateTime? get extractedAt;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentImplCopyWith<_$DocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
