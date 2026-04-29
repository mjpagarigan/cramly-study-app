import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/bottom_sheet_shell.dart';
import '../data/deck_model.dart';
import '../providers/deck_providers.dart';

Future<Deck?> showDeckFormSheet(
  BuildContext context, {
  required String courseId,
  Deck? existing,
}) {
  return showModalBottomSheet<Deck?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    builder: (_) => _DeckFormSheet(courseId: courseId, existing: existing),
  );
}

class _DeckFormSheet extends ConsumerStatefulWidget {
  const _DeckFormSheet({required this.courseId, this.existing});

  final String courseId;
  final Deck? existing;

  @override
  ConsumerState<_DeckFormSheet> createState() => _DeckFormSheetState();
}

class _DeckFormSheetState extends ConsumerState<_DeckFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final repo = ref.read(deckRepositoryProvider);
      final deck = widget.existing == null
          ? await repo.createManualDeck(
              courseId: widget.courseId,
              title: title,
              description: description,
            )
          : await repo.updateDeck(
              widget.existing!.id,
              title: title,
              description: description,
            );
      if (!mounted) return;
      Navigator.of(context).pop(deck);
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
    final isEdit = widget.existing != null;
    final c = context.colors;

    return BottomSheetShell(
      title: isEdit ? 'Edit deck' : 'New deck',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetField(
            controller: _titleController,
            placeholder: 'Deck title',
            autofocus: !isEdit,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Spacing.md),
          _SheetField(
            controller: _descriptionController,
            placeholder: 'Short description (optional)',
            maxLines: 3,
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
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.placeholder,
    this.autofocus = false,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      minLines: maxLines > 1 ? maxLines : 1,
      maxLines: maxLines,
      textInputAction: textInputAction,
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
