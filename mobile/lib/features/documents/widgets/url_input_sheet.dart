import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/bottom_sheet_shell.dart';
import '../data/document_model.dart';
import '../providers/upload_state.dart';

/// One sheet for both YouTube and Web URL — the only difference is the title,
/// placeholder, and which DocumentSourceType the result carries.
Future<void> showUrlInputSheet(
  BuildContext context,
  WidgetRef ref, {
  required DocumentSourceType sourceType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    builder: (_) => _UrlInputSheet(sourceType: sourceType),
  );
}

class _UrlInputSheet extends ConsumerStatefulWidget {
  const _UrlInputSheet({required this.sourceType});
  final DocumentSourceType sourceType;

  @override
  ConsumerState<_UrlInputSheet> createState() => _UrlInputSheetState();
}

class _UrlInputSheetState extends ConsumerState<_UrlInputSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isYouTube => widget.sourceType == DocumentSourceType.youtube;

  void _confirm() {
    final raw = _controller.text.trim();
    final validationError = validateSourceUrl(raw, widget.sourceType);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    ref
        .read(uploadControllerProvider.notifier)
        .pickedSource(
          UploadSource.url(url: raw, sourceType: widget.sourceType),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return BottomSheetShell(
      title: _isYouTube ? 'YouTube video' : 'Web article',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isYouTube
                ? 'Paste any YouTube link — full URL, shorts, or just the video ID.'
                : 'Paste an article URL. Works best on news + blog sites; paywalled or JS-heavy pages may fail.',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
          const SizedBox(height: Spacing.md),
          AppInput(
            controller: _controller,
            label: _isYouTube ? 'YouTube URL or video ID' : 'Article URL',
            placeholder: _isYouTube
                ? 'https://youtube.com/watch?v=...'
                : 'https://example.com/article',
            icon: _isYouTube ? Icons.play_circle_outline : Icons.link,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            autofocus: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(_error!, style: TextStyle(color: c.error, fontSize: 13)),
          ],
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: AppButton(label: 'Use this', onPressed: _confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? validateSourceUrl(String raw, DocumentSourceType sourceType) {
  final value = raw.trim();
  if (value.isEmpty) return 'Paste a URL';

  if (sourceType == DocumentSourceType.youtube) {
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value)) return null;

    final candidate = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid YouTube link or 11-character video ID';
    }
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    String id = '';
    if (host == 'youtu.be' && segments.length == 1) {
      id = segments.single;
    } else if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
      if (uri.path == '/watch') {
        id = uri.queryParameters['v'] ?? '';
      } else if (segments.length == 2 &&
          const {'shorts', 'embed', 'v'}.contains(segments.first)) {
        id = segments[1];
      }
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
      return 'Enter a YouTube watch, Shorts, embed, youtu.be link, or video ID';
    }
    return null;
  }

  final uri = Uri.tryParse(value);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      _isPrivateHost(uri.host)) {
    return 'Enter a complete public http:// or https:// URL';
  }
  return null;
}

bool _isPrivateHost(String rawHost) {
  final host = rawHost.toLowerCase();
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local')) {
    return true;
  }

  final address = InternetAddress.tryParse(host);
  if (address == null) return false;
  final bytes = address.rawAddress;
  if (bytes.length == 4) return _isPrivateIpv4(bytes);
  if (bytes.length != 16) return true;

  final unspecified = bytes.every((byte) => byte == 0);
  final uniqueLocal = (bytes[0] & 0xfe) == 0xfc;
  final siteLocal = bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0xc0;
  final mappedIpv4 =
      bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  final compatibleIpv4 = bytes.take(12).every((byte) => byte == 0);
  if (unspecified ||
      address.isLoopback ||
      address.isLinkLocal ||
      address.isMulticast ||
      uniqueLocal ||
      siteLocal) {
    return true;
  }
  return (mappedIpv4 || compatibleIpv4)
      ? _isPrivateIpv4(bytes.sublist(12))
      : false;
}

bool _isPrivateIpv4(List<int> octets) {
  final a = octets[0];
  final b = octets[1];
  return a == 0 ||
      a == 10 ||
      a == 127 ||
      (a == 100 && b >= 64 && b <= 127) ||
      (a == 169 && b == 254) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && b == 168) ||
      (a == 198 && (b == 18 || b == 19)) ||
      a >= 224;
}
