import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../courses/data/course_model.dart';
import '../../courses/providers/course_providers.dart';
import '../../courses/widgets/course_form_sheet.dart';
import '../data/document_model.dart';
import '../providers/document_providers.dart';
import '../providers/upload_state.dart';
import '../widgets/file_picker_helpers.dart';
import '../widgets/url_input_sheet.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key, this.preselectedCourseId});

  /// When entered from a Course detail screen, the course is preselected.
  final String? preselectedCourseId;

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preselectedCourseId != null) {
      // Defer until after first frame so the controller exists.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(uploadControllerProvider.notifier)
            .selectCourse(widget.preselectedCourseId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadControllerProvider);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, state.step),
        ),
        title: Text(_titleFor(state.step)),
      ),
      body: SafeArea(
        child: switch (state.step) {
          UploadStep.source => const _SourceStep(),
          UploadStep.assign => const _AssignStep(),
          UploadStep.processing => _ProcessingStep(
              preselectedCourseId: widget.preselectedCourseId,
            ),
          UploadStep.done => const _DoneStep(),
        },
      ),
      backgroundColor: c.bgCard.withValues(alpha: 0),
    );
  }

  static String _titleFor(UploadStep step) => switch (step) {
        UploadStep.source => 'Upload',
        UploadStep.assign => 'Assign to course',
        UploadStep.processing => 'Processing',
        UploadStep.done => 'Done',
      };

  Future<void> _confirmExit(BuildContext context, UploadStep step) async {
    if (step == UploadStep.processing) {
      // Don't let user back out mid-upload.
      return;
    }
    ref.read(uploadControllerProvider.notifier).reset();
    if (context.mounted) context.pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Source picker
// ─────────────────────────────────────────────────────────────────────────────

class _SourceStep extends ConsumerWidget {
  const _SourceStep();

  static const _formats = [
    _FormatTile(label: 'PDF', icon: Icons.picture_as_pdf, sub: '.pdf'),
    _FormatTile(label: 'DOCX', icon: Icons.description, sub: '.docx'),
    _FormatTile(label: 'PPTX', icon: Icons.slideshow, sub: '.pptx'),
    _FormatTile(label: 'Image', icon: Icons.image, sub: 'OCR'),
    _FormatTile(label: 'Audio', icon: Icons.mic, sub: 'Whisper'),
    _FormatTile(label: 'YouTube', icon: Icons.play_circle, sub: 'URL'),
    _FormatTile(label: 'Web', icon: Icons.link, sub: 'URL'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(uploadControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxxl,
      ),
      children: [
        Text(
          'Add study material',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a file or paste a URL — we\'ll extract the text.',
          style: TextStyle(fontSize: 14, color: c.textMuted),
        ),
        const SizedBox(height: Spacing.xl),
        InkWell(
          onTap: () => _pickFile(ref),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: DottedBox(
            color: c.border,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.xxxl,
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.accentSubtle,
                      borderRadius: Radii.cardRadius,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.upload, color: c.accent, size: 24),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Tap to upload a file',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, DOCX, PPTX, image, audio',
                    style: TextStyle(fontSize: 13, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        const AppSectionHeader(label: 'Or add from'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: Spacing.sm,
          mainAxisSpacing: Spacing.sm,
          childAspectRatio: 1.1,
          children: [
            for (final fmt in _formats)
              _FormatTileWidget(
                tile: fmt,
                onTap: () => _onFormatTap(context, ref, fmt.label),
              ),
          ],
        ),
        if (state.source != null) ...[
          const SizedBox(height: Spacing.xl),
          const AppSectionHeader(label: 'Selected'),
          _SelectedSourceCard(
            source: state.source!,
            onClear: () =>
                ref.read(uploadControllerProvider.notifier).clearSource(),
          ),
          const SizedBox(height: Spacing.lg),
          AppButton(
            label: 'Continue',
            fullWidth: true,
            onPressed: () =>
                ref.read(uploadControllerProvider.notifier).goToAssign(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile(WidgetRef ref) async {
    final source = await pickAndBuildSource();
    if (source == null) return;
    ref.read(uploadControllerProvider.notifier).pickedSource(source);
  }

  Future<void> _onFormatTap(
    BuildContext context,
    WidgetRef ref,
    String label,
  ) async {
    if (label == 'YouTube') {
      await showUrlInputSheet(context, ref,
          sourceType: DocumentSourceType.youtube);
      return;
    }
    if (label == 'Web') {
      await showUrlInputSheet(context, ref,
          sourceType: DocumentSourceType.webUrl);
      return;
    }
    // Everything else routes through the same file picker.
    await _pickFile(ref);
  }
}

class _FormatTile {
  const _FormatTile({required this.label, required this.icon, required this.sub});
  final String label;
  final IconData icon;
  final String sub;
}

class _FormatTileWidget extends StatelessWidget {
  const _FormatTileWidget({required this.tile, required this.onTap});
  final _FormatTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tile.icon, size: 22, color: c.accent),
          const SizedBox(height: 6),
          Text(
            tile.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          Text(
            tile.sub,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SelectedSourceCard extends StatelessWidget {
  const _SelectedSourceCard({required this.source, required this.onClear});
  final UploadSource source;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, primary, secondary) = _displayFor(source);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 44,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: c.accent),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: c.textMuted),
            onPressed: onClear,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  (IconData, String, String) _displayFor(UploadSource s) {
    if (s.isFile) {
      final size = formatBytes(s.fileSize ?? 0);
      return (
        Icons.insert_drive_file,
        s.fileName ?? 'file',
        '$size · ${s.sourceType.toJson().toUpperCase()}',
      );
    }
    final label = s.sourceType == DocumentSourceType.youtube ? 'YouTube' : 'Web';
    return (
      s.sourceType == DocumentSourceType.youtube ? Icons.play_circle : Icons.link,
      s.url ?? '',
      label,
    );
  }
}

/// Lightweight dotted border (Flutter doesn't ship a dashed BorderSide).
class DottedBox extends StatelessWidget {
  const DottedBox({super.key, required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: color, width: 2),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Course assign
// ─────────────────────────────────────────────────────────────────────────────

class _AssignStep extends ConsumerWidget {
  const _AssignStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(uploadControllerProvider);
    final coursesAsync = ref.watch(coursesStreamProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxxl,
      ),
      children: [
        Text(
          'Assign to course',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Where should this material live?',
          style: TextStyle(fontSize: 14, color: c.textMuted),
        ),
        const SizedBox(height: Spacing.xl),
        coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Failed to load courses: $e',
            style: TextStyle(color: c.error),
          ),
          data: (courses) {
            if (courses.isEmpty) {
              return AppCard(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 32, color: c.textMuted),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'No courses yet — create one first.',
                      style: TextStyle(fontSize: 14, color: c.textPrimary),
                    ),
                    const SizedBox(height: Spacing.md),
                    AppButton(
                      label: 'New course',
                      icon: Icons.add,
                      onPressed: () async {
                        final created = await showCourseFormSheet(context);
                        if (created != null) {
                          ref
                              .read(uploadControllerProvider.notifier)
                              .selectCourse(created.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final course in courses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _CourseRow(
                      course: course,
                      selected: state.courseId == course.id,
                      onTap: () => ref
                          .read(uploadControllerProvider.notifier)
                          .selectCourse(course.id),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xl),
                  child: InkWell(
                    onTap: () async {
                      final created = await showCourseFormSheet(context);
                      if (created != null) {
                        ref
                            .read(uploadControllerProvider.notifier)
                            .selectCourse(created.id);
                      }
                    },
                    borderRadius: Radii.cardRadius,
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: Radii.cardRadius,
                        border: Border.all(color: c.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: c.accent),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            'Create new course',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: c.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        AppButton(
          label: 'Start',
          fullWidth: true,
          onPressed: state.courseId == null
              ? null
              : () => _kickOff(context, ref),
        ),
      ],
    );
  }

  void _kickOff(BuildContext context, WidgetRef ref) {
    ref.read(uploadControllerProvider.notifier).goToProcessing();
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.course,
    required this.selected,
    required this.onTap,
  });
  final Course course;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = hexToColor(course.color);
    return AppCard(
      onTap: onTap,
      borderColor: selected ? c.accent.withValues(alpha: 0.4) : c.border,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              course.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: c.textPrimary,
              ),
            ),
          ),
          if (selected) Icon(Icons.check_circle, size: 20, color: c.accent),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Processing
// ─────────────────────────────────────────────────────────────────────────────

class _ProcessingStep extends ConsumerStatefulWidget {
  const _ProcessingStep({this.preselectedCourseId});
  final String? preselectedCourseId;

  @override
  ConsumerState<_ProcessingStep> createState() => _ProcessingStepState();
}

class _ProcessingStepState extends ConsumerState<_ProcessingStep> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runUploadAndCreate());
  }

  Future<void> _runUploadAndCreate() async {
    if (_started) return;
    _started = true;

    final state = ref.read(uploadControllerProvider);
    final controller = ref.read(uploadControllerProvider.notifier);
    final repo = ref.read(documentRepositoryProvider);
    final source = state.source!;
    final courseId = state.courseId!;

    try {
      Document doc;
      if (source.isFile) {
        final ext = (source.fileName ?? '').contains('.')
            ? '.${source.fileName!.split('.').last}'
            : '';
        final storagePath = repo.buildStoragePath(fileExtension: ext);

        await for (final progress in repo.uploadFile(
          file: source.file!,
          storagePath: storagePath,
          contentType: source.mimeType,
        )) {
          controller.updateUploadProgress(progress.fraction);
        }

        doc = await repo.createFromFile(
          courseId: courseId,
          sourceType: source.sourceType,
          fileName: source.fileName!,
          fileSize: source.fileSize ?? 0,
          storagePath: storagePath,
          mimeType: source.mimeType,
        );
      } else {
        // URL source — no upload step. Backend fetches the URL itself.
        controller.updateUploadProgress(1);
        doc = await repo.createFromUrl(
          courseId: courseId,
          sourceType: source.sourceType,
          url: source.url!,
        );
      }

      controller.markCreated(doc.id);
      controller.markDone();
    } catch (e) {
      if (mounted) controller.fail(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(uploadControllerProvider);
    final pct = (state.uploadFraction * 100).clamp(0, 100).toInt();
    final isUrlSource = state.source?.isFile == false;

    final stepLabel = state.uploadFraction < 1
        ? 'Uploading'
        : (isUrlSource ? 'Fetching + extracting' : 'Extracting text');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xxxl,
        Spacing.xl,
        Spacing.xxxl,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: state.uploadFraction == 0 ? null : state.uploadFraction,
                    strokeWidth: 5,
                    color: c.accent,
                    backgroundColor: c.border,
                  ),
                ),
                Text(
                  '$pct%',
                  style: AppTheme.mono(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            stepLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            isUrlSource
                ? 'Pulling content and extracting text...'
                : 'Uploading file, then extracting text...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textMuted),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: Spacing.xl),
            AppCard(
              borderColor: c.error.withValues(alpha: 0.3),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: c.error, size: 28),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Upload failed',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textMuted),
                  ),
                  const SizedBox(height: Spacing.md),
                  AppButton(
                    label: 'Try again',
                    onPressed: () =>
                        ref.read(uploadControllerProvider.notifier).reset(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Done
// ─────────────────────────────────────────────────────────────────────────────

class _DoneStep extends ConsumerWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(uploadControllerProvider);
    final docId = state.createdDocumentId;
    final doc = docId == null
        ? null
        : ref.watch(documentByIdProvider(docId)).valueOrNull;

    final failed = doc?.status == DocumentStatus.failed;
    final ready = doc?.status == DocumentStatus.ready;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xxxl,
        Spacing.xl,
        Spacing.xxxl,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: failed ? c.errorSubtle : c.successSubtle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              failed ? Icons.error_outline : Icons.check,
              size: 32,
              color: failed ? c.error : c.success,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            failed ? 'Extraction failed' : (ready ? 'All done' : 'Processing...'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            failed
                ? (doc?.errorMessage ?? 'Something went wrong during extraction.')
                : (ready
                    ? 'Your study material is ready.'
                    : 'Hang tight — backend is finishing up.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textMuted),
          ),
          const Spacer(),
          if (state.courseId != null)
            AppButton(
              label: 'View in course',
              fullWidth: true,
              onPressed: () {
                ref.read(uploadControllerProvider.notifier).reset();
                context.go('/library/${state.courseId}');
              },
            ),
          const SizedBox(height: Spacing.sm),
          AppButton(
            label: 'Upload more',
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: () =>
                ref.read(uploadControllerProvider.notifier).reset(),
          ),
        ],
      ),
    );
  }
}
