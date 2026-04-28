import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_model.dart';

enum UploadStep { source, assign, processing, done }

/// Source picked at step 1. Either a local file (PDF/DOCX/PPTX/image/audio)
/// or a URL (YouTube/web article).
class UploadSource {
  const UploadSource.file({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.sourceType,
    this.mimeType,
  })  : url = null,
        assert(sourceType != DocumentSourceType.youtube &&
            sourceType != DocumentSourceType.webUrl);

  const UploadSource.url({
    required this.url,
    required this.sourceType,
  })  : file = null,
        fileName = null,
        fileSize = null,
        mimeType = null,
        assert(sourceType == DocumentSourceType.youtube ||
            sourceType == DocumentSourceType.webUrl);

  final File? file;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? url;
  final DocumentSourceType sourceType;

  bool get isFile => file != null;
}

class UploadState {
  const UploadState({
    this.step = UploadStep.source,
    this.source,
    this.courseId,
    this.uploadFraction = 0,
    this.createdDocumentId,
    this.errorMessage,
  });

  final UploadStep step;
  final UploadSource? source;
  final String? courseId;
  final double uploadFraction;
  final String? createdDocumentId;
  final String? errorMessage;

  UploadState copyWith({
    UploadStep? step,
    UploadSource? source,
    String? courseId,
    double? uploadFraction,
    String? createdDocumentId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UploadState(
      step: step ?? this.step,
      source: source ?? this.source,
      courseId: courseId ?? this.courseId,
      uploadFraction: uploadFraction ?? this.uploadFraction,
      createdDocumentId: createdDocumentId ?? this.createdDocumentId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UploadController extends StateNotifier<UploadState> {
  UploadController() : super(const UploadState());

  void pickedSource(UploadSource source) {
    state = state.copyWith(source: source, clearError: true);
  }

  void clearSource() {
    state = const UploadState();
  }

  void goToAssign() {
    if (state.source == null) return;
    state = state.copyWith(step: UploadStep.assign, clearError: true);
  }

  void selectCourse(String courseId) {
    state = state.copyWith(courseId: courseId);
  }

  void goToProcessing() {
    state = state.copyWith(step: UploadStep.processing, uploadFraction: 0);
  }

  void updateUploadProgress(double fraction) {
    state = state.copyWith(uploadFraction: fraction);
  }

  void markCreated(String documentId) {
    state = state.copyWith(createdDocumentId: documentId);
  }

  void markDone() {
    state = state.copyWith(step: UploadStep.done);
  }

  void fail(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void reset() {
    state = const UploadState();
  }
}

final uploadControllerProvider =
    StateNotifierProvider.autoDispose<UploadController, UploadState>((ref) {
  return UploadController();
});
