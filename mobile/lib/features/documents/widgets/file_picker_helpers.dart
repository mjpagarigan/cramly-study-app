import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../data/document_model.dart';
import '../providers/upload_state.dart';

const _pdfExt = ['pdf'];
const _docxExt = ['docx'];
const _pptxExt = ['pptx'];
const _markdownExt = ['md', 'markdown'];
const _imageExt = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'tif', 'tiff'];
const _audioExt = ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'webm'];

const maxUploadBytes = 50 * 1024 * 1024;
const maxAudioUploadBytes = 25 * 1024 * 1024;

const _allowedExtensions = [
  ..._pdfExt,
  ..._docxExt,
  ..._pptxExt,
  ..._markdownExt,
  ..._imageExt,
  ..._audioExt,
];

class UnsupportedFileException implements Exception {
  UnsupportedFileException(this.message);
  final String message;
  @override
  String toString() => message;
}

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
  if (_markdownExt.contains(lower)) {
    return (type: DocumentSourceType.markdown, mimeType: 'text/markdown');
  }
  if (_imageExt.contains(lower)) {
    final mimeType = switch (lower) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'tif' || 'tiff' => 'image/tiff',
      _ => 'image/$lower',
    };
    return (type: DocumentSourceType.image, mimeType: mimeType);
  }
  if (_audioExt.contains(lower)) {
    final mimeType = switch (lower) {
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      _ => 'audio/$lower',
    };
    return (type: DocumentSourceType.audio, mimeType: mimeType);
  }
  return null;
}

List<String> _extensionsFor(DocumentSourceType type) => switch (type) {
  DocumentSourceType.pdf => _pdfExt,
  DocumentSourceType.docx => _docxExt,
  DocumentSourceType.pptx => _pptxExt,
  DocumentSourceType.markdown => _markdownExt,
  DocumentSourceType.image => _imageExt,
  DocumentSourceType.audio => _audioExt,
  _ => _allowedExtensions,
};

/// Opens the system file picker. When [only] is null, uses `FileType.any` so
/// Android's SAF doesn't get confused by a multi-MIME custom request and
/// default to a single source like Google Drive. When [only] is a specific
/// format, uses a tighter `FileType.custom` filter for that format only.
///
/// Returns null if the user cancelled. Throws [UnsupportedFileException] if
/// the user picked something that isn't a supported study material.
Future<UploadSource?> pickAndBuildSource({DocumentSourceType? only}) async {
  final result = only == null
      ? await FilePicker.platform.pickFiles(type: FileType.any)
      : await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: _extensionsFor(only),
        );

  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.single;
  if (picked.path == null) {
    throw UnsupportedFileException(
      'Could not read this file. Try downloading it locally first if it\'s on Drive.',
    );
  }

  final ext = (picked.extension ?? '').toLowerCase();
  final mapping = sourceTypeForExt(ext);
  if (mapping == null) {
    throw UnsupportedFileException(
      'Unsupported file type: .${ext.isEmpty ? '?' : ext}. '
      'Pick a PDF, DOCX, PPTX, Markdown, image, or audio file.',
    );
  }

  if (only != null && mapping.type != only) {
    throw UnsupportedFileException(
      'Expected ${only.name.toUpperCase()}, got .$ext',
    );
  }

  final sizeError = validateUploadSize(picked.size, sourceType: mapping.type);
  if (sizeError != null) {
    throw UnsupportedFileException(sizeError);
  }

  return UploadSource.file(
    file: File(picked.path!),
    fileName: picked.name,
    fileSize: picked.size,
    sourceType: mapping.type,
    mimeType: mapping.mimeType,
  );
}

String? validateUploadSize(
  int bytes, {
  required DocumentSourceType sourceType,
}) {
  if (bytes >= maxUploadBytes) {
    return 'Files must be smaller than 50 MiB. This file is ${formatBytes(bytes)}.';
  }
  if (sourceType == DocumentSourceType.audio && bytes > maxAudioUploadBytes) {
    return 'Audio files must be 25 MiB or smaller. This file is ${formatBytes(bytes)}.';
  }
  return null;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MiB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GiB';
}
