import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/bottom_sheet_shell.dart';
import '../data/deck_model.dart';
import '../providers/deck_providers.dart';

Future<DeckCardItem?> showCardFormSheet(
  BuildContext context, {
  required String deckId,
  DeckCardItem? existing,
}) {
  return showModalBottomSheet<DeckCardItem?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    builder: (_) => _CardFormSheet(deckId: deckId, existing: existing),
  );
}

class _CardFormSheet extends ConsumerStatefulWidget {
  const _CardFormSheet({required this.deckId, this.existing});

  final String deckId;
  final DeckCardItem? existing;

  @override
  ConsumerState<_CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends ConsumerState<_CardFormSheet> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _hintController;
  late final TextEditingController _explanationController;
  late final TextEditingController _topicController;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(
      text: widget.existing?.front ?? '',
    );
    _backController = TextEditingController(text: widget.existing?.back ?? '');
    _hintController = TextEditingController(text: widget.existing?.hint ?? '');
    _explanationController = TextEditingController(
      text: widget.existing?.explanation ?? '',
    );
    _topicController = TextEditingController(
      text: widget.existing?.topic ?? '',
    );
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _hintController.dispose();
    _explanationController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    if (front.isEmpty || back.isEmpty) {
      setState(() => _error = 'Front and back are required');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final repo = ref.read(deckRepositoryProvider);
      final card = widget.existing == null
          ? await repo.createCard(
              widget.deckId,
              front: front,
              back: back,
              hint: _hintController.text.trim(),
              explanation: _explanationController.text.trim(),
              topic: _topicController.text.trim(),
            )
          : await repo.updateCard(
              widget.deckId,
              widget.existing!.id,
              front: front,
              back: back,
              hint: _hintController.text.trim(),
              explanation: _explanationController.text.trim(),
              topic: _topicController.text.trim(),
            );
      if (!mounted) return;
      Navigator.of(context).pop(card);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEdit = widget.existing != null;

    return BottomSheetShell(
      title: isEdit ? 'Edit card' : 'New card',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetField(
              controller: _frontController,
              placeholder: 'Front',
              autofocus: !isEdit,
              maxLines: 2,
            ),
            const SizedBox(height: Spacing.md),
            _SheetField(
              controller: _backController,
              placeholder: 'Back',
              maxLines: 3,
            ),
            const SizedBox(height: Spacing.md),
            _SheetField(
              controller: _hintController,
              placeholder: 'Hint (optional)',
              maxLines: 2,
            ),
            const SizedBox(height: Spacing.md),
            _SheetField(
              controller: _explanationController,
              placeholder: 'Explanation (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: Spacing.md),
            _SheetField(
              controller: _topicController,
              placeholder: 'Topic (optional)',
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.md),
              Text(_error!, style: TextStyle(color: c.error, fontSize: 13)),
            ],
            const SizedBox(height: Spacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: AppButton(
                    label: isEdit ? 'Save' : 'Create',
                    busy: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.placeholder,
    this.autofocus = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      minLines: maxLines > 1 ? maxLines : 1,
      maxLines: maxLines,
      style: TextStyle(color: c.textPrimary, fontSize: 15),
      cursorColor: c.accent,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
        filled: true,
        fillColor: c.bgInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
      ),
    );
  }
}
