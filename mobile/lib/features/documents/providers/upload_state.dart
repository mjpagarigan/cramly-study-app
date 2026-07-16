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
  }) : url = null,
       assert(
         sourceType != DocumentSourceType.youtube &&
             sourceType != DocumentSourceType.webUrl,
       );

  const UploadSource.url({required this.url, required this.sourceType})
    : file = null,
      fileName = null,
      fileSize = null,
      mimeType = null,
      assert(
        sourceType == DocumentSourceType.youtube ||
            sourceType == DocumentSourceType.webUrl,
      );

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
    this.uploadedStoragePath,
    this.errorMessage,
  });

  final UploadStep step;
  final UploadSource? source;
  final String? courseId;
  final double uploadFraction;
  final String? createdDocumentId;

  /// Retained after a successful Storage upload so a failed API registration
  /// can be retried without uploading the same object again.
  final String? uploadedStoragePath;
  final String? errorMessage;

  UploadState copyWith({
    UploadStep? step,
    UploadSource? source,
    String? courseId,
    double? uploadFraction,
    String? createdDocumentId,
    String? uploadedStoragePath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UploadState(
      step: step ?? this.step,
      source: source ?? this.source,
      courseId: courseId ?? this.courseId,
      uploadFraction: uploadFraction ?? this.uploadFraction,
      createdDocumentId: createdDocumentId ?? this.createdDocumentId,
      uploadedStoragePath: uploadedStoragePath ?? this.uploadedStoragePath,
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
    state = UploadState(courseId: state.courseId);
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

  void markStorageUploaded(String storagePath) {
    state = state.copyWith(uploadedStoragePath: storagePath, uploadFraction: 1);
  }

  void markDone() {
    state = state.copyWith(step: UploadStep.done);
  }

  void fail(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void retryProcessing() {
    state = state.copyWith(step: UploadStep.processing, clearError: true);
  }

  void reset({String? courseId}) {
    state = UploadState(courseId: courseId);
  }
}

final uploadControllerProvider =
    StateNotifierProvider.autoDispose<UploadController, UploadState>((ref) {
      return UploadController();
    });
