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
    if (raw.isEmpty) {
      setState(() => _error = 'Paste a URL');
      return;
    }
    if (_isYouTube && !raw.contains('youtu')) {
      setState(() => _error = 'That doesn\'t look like a YouTube URL');
      return;
    }
    if (!_isYouTube && !(raw.startsWith('http://') || raw.startsWith('https://'))) {
      setState(() => _error = 'URL must start with http:// or https://');
      return;
    }

    ref.read(uploadControllerProvider.notifier).pickedSource(
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
