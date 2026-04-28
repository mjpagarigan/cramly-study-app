import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/bottom_sheet_shell.dart';
import '../data/course_model.dart';
import '../providers/course_providers.dart';

const courseColorPalette = <String>[
  '#E8A84C', // amber
  '#4CC8E8', // cyan
  '#5CB87A', // green
  '#E85C5C', // red
  '#B47CE8', // purple
  '#E87CB4', // pink
  '#E8845C', // orange
  '#5CE8B4', // teal
];

Future<Course?> showCourseFormSheet(
  BuildContext context, {
  Course? existing,
}) {
  return showModalBottomSheet<Course?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    builder: (_) => _CourseFormSheet(existing: existing),
  );
}

class _CourseFormSheet extends ConsumerStatefulWidget {
  const _CourseFormSheet({this.existing});
  final Course? existing;

  @override
  ConsumerState<_CourseFormSheet> createState() => _CourseFormSheetState();
}

class _CourseFormSheetState extends ConsumerState<_CourseFormSheet> {
  late final TextEditingController _nameController;
  late String _color;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color ?? courseColorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final controller = ref.read(courseControllerProvider.notifier);
    final result = widget.existing == null
        ? await controller.create(name: name, color: _color)
        : await controller.update(
            widget.existing!.id,
            name: name,
            color: _color,
          );

    if (!mounted) return;
    if (result == null) {
      final err = ref.read(courseControllerProvider);
      setState(() {
        _busy = false;
        _error = err.error?.toString() ?? 'Something went wrong';
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEdit = widget.existing != null;

    return BottomSheetShell(
      title: isEdit ? 'Edit course' : 'New course',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _nameController,
            placeholder: 'e.g. Organic Chemistry',
            autofocus: !isEdit,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              for (final hex in courseColorPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == hex ? c.textPrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _color == hex
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: c.textOnAccent,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _error!,
              style: TextStyle(color: c.error, fontSize: 13),
            ),
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

Color hexToColor(String hex) => _hexToColor(hex);

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
