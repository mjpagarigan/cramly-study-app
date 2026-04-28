import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../data/document_model.dart';
import '../providers/upload_state.dart';

const _pdfExt = ['pdf'];
const _docxExt = ['docx'];
const _pptxExt = ['pptx'];
const _imageExt = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'tiff'];
const _audioExt = ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'webm'];

const allowedExtensions = [
  ..._pdfExt,
  ..._docxExt,
  ..._pptxExt,
  ..._imageExt,
  ..._audioExt,
];

/// Maps a file's extension to its `DocumentSourceType` and a sensible
/// MIME type. Returns null for unsupported extensions.
({DocumentSourceType type, String mimeType})? sourceTypeForExt(String ext) {
  final lower = ext.toLowerCase();
  if (_pdfExt.contains(lower)) {
    return (type: DocumentSourceType.pdf, mimeType: 'application/pdf');
  }
  if (_docxExt.contains(lower)) {
    return (
      type: DocumentSourceType.docx,
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }
  if (_pptxExt.contains(lower)) {
    return (
      type: DocumentSourceType.pptx,
      mimeType:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    );
  }
  if (_imageExt.contains(lower)) {
    return (type: DocumentSourceType.image, mimeType: 'image/$lower');
  }
  if (_audioExt.contains(lower)) {
    return (type: DocumentSourceType.audio, mimeType: 'audio/$lower');
  }
  return null;
}

Future<UploadSource?> pickAndBuildSource() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.single;
  if (picked.path == null) return null;

  final ext = picked.extension ?? '';
  final mapping = sourceTypeForExt(ext);
  if (mapping == null) return null;

  return UploadSource.file(
    file: File(picked.path!),
    fileName: picked.name,
    fileSize: picked.size,
    sourceType: mapping.type,
    mimeType: mapping.mimeType,
  );
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}
