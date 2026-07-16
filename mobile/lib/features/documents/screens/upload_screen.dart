import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/learning_trace.dart';
import '../../courses/data/course_model.dart';
import '../../courses/providers/course_providers.dart';
import '../../courses/widgets/course_form_sheet.dart';
import '../../jobs/data/async_job_model.dart';
import '../../jobs/providers/job_providers.dart';
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
    final uploadIsActive =
        state.step == UploadStep.processing && state.errorMessage == null;

    return PopScope(
      canPop: !uploadIsActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && uploadIsActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Keep Cramly open until this upload is registered.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context, state),
          ),
          title: Text(_titleFor(state.step)),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.xl,
                  0,
                ),
                child: _UploadStageIndicator(step: state.step),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.xl,
                  0,
                ),
                child: LearningTrace(width: 112, height: 20),
              ),
              Expanded(
                child: switch (state.step) {
                  UploadStep.source => const _SourceStep(),
                  UploadStep.assign => const _AssignStep(),
                  UploadStep.processing => _ProcessingStep(
                    preselectedCourseId: widget.preselectedCourseId,
                  ),
                  UploadStep.done => const _DoneStep(),
                },
              ),
            ],
          ),
        ),
        backgroundColor: c.bgCard.withValues(alpha: 0),
      ),
    );
  }

  static String _titleFor(UploadStep step) => switch (step) {
    UploadStep.source => 'Upload',
    UploadStep.assign => 'Assign to course',
    UploadStep.processing => 'Processing',
    UploadStep.done => 'Done',
  };

  Future<void> _confirmExit(BuildContext context, UploadState state) async {
    if (state.step == UploadStep.processing && state.errorMessage == null) {
      // Don't let user back out mid-upload.
      return;
    }
    ref
        .read(uploadControllerProvider.notifier)
        .reset(courseId: widget.preselectedCourseId);
    if (context.mounted) context.pop();
  }
}

class _UploadStageIndicator extends StatelessWidget {
  const _UploadStageIndicator({required this.step});

  final UploadStep step;

  static const _labels = ['Choose', 'Review', 'Process', 'Ready'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = step.index;
    return Semantics(
      label: 'Upload step ${current + 1} of 4, ${_labels[current]}',
      child: Row(
        children: [
          for (var index = 0; index < _labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= current ? c.primary : c.surfaceSoft,
                      border: Border.all(
                        color: index <= current ? c.primary : c.border,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= current ? c.textOnAccent : c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      color: index == current ? c.foreground : c.muted,
                      fontSize: 11,
                      fontWeight: index == current
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (index != _labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  color: index < current ? c.primary : c.border,
                ),
              ),
          ],
        ],
      ),
    );
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
    _FormatTile(label: 'Markdown', icon: Icons.notes, sub: '.md'),
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
          'Choose material',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a supported file or URL, then review it before uploading.',
          style: TextStyle(fontSize: 14, color: c.textMuted),
        ),
        const SizedBox(height: Spacing.xl),
        InkWell(
          onTap: () => _pickFile(context, ref),
          borderRadius: Radii.cardRadius,
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
                    'PDF, DOCX, PPTX, MD, image, audio',
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
            label: 'Review and assign',
            fullWidth: true,
            onPressed: () =>
                ref.read(uploadControllerProvider.notifier).goToAssign(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    WidgetRef ref, {
    DocumentSourceType? only,
  }) async {
    try {
      final source = await pickAndBuildSource(only: only);
      if (source == null) return;
      ref.read(uploadControllerProvider.notifier).pickedSource(source);
    } on UnsupportedFileException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Couldn\'t pick file: $e')));
    }
  }

  Future<void> _onFormatTap(
    BuildContext context,
    WidgetRef ref,
    String label,
  ) async {
    final type = switch (label) {
      'PDF' => DocumentSourceType.pdf,
      'DOCX' => DocumentSourceType.docx,
      'PPTX' => DocumentSourceType.pptx,
      'Markdown' => DocumentSourceType.markdown,
      'Image' => DocumentSourceType.image,
      'Audio' => DocumentSourceType.audio,
      'YouTube' => DocumentSourceType.youtube,
      'Web' => DocumentSourceType.webUrl,
      _ => null,
    };

    if (type == DocumentSourceType.youtube ||
        type == DocumentSourceType.webUrl) {
      await showUrlInputSheet(context, ref, sourceType: type!);
      return;
    }
    // Format tile → narrow picker for that one format. Single-MIME requests
    // are way more reliable on Android SAF than mixed-MIME ones.
    await _pickFile(context, ref, only: type);
  }
}

class _FormatTile {
  const _FormatTile({
    required this.label,
    required this.icon,
    required this.sub,
  });
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
          Text(tile.sub, style: TextStyle(fontSize: 11, color: c.textMuted)),
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
    final label = s.sourceType == DocumentSourceType.youtube
        ? 'YouTube'
        : 'Web';
    return (
      s.sourceType == DocumentSourceType.youtube
          ? Icons.play_circle
          : Icons.link,
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
        borderRadius: Radii.cardRadius,
        border: Border.all(color: color),
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
          'Review and assign',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm the material and choose where it should live.',
          style: TextStyle(fontSize: 14, color: c.textMuted),
        ),
        const SizedBox(height: Spacing.xl),
        if (state.source != null) ...[
          const AppSectionHeader(label: 'Material'),
          _SelectedSourceCard(
            source: state.source!,
            onClear: () {
              ref.read(uploadControllerProvider.notifier).clearSource();
            },
          ),
          const SizedBox(height: Spacing.xl),
        ],
        const AppSectionHeader(label: 'Course'),
        coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppCard(
            borderColor: c.error.withValues(alpha: 0.35),
            child: Column(
              children: [
                Text(
                  'Couldn’t load courses.',
                  style: TextStyle(color: c.textPrimary),
                ),
                const SizedBox(height: Spacing.sm),
                AppButton(
                  label: 'Try again',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => ref.invalidate(coursesStreamProvider),
                ),
              ],
            ),
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
          label: 'Upload and process',
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
        final storagePath =
            state.uploadedStoragePath ??
            repo.buildStoragePath(fileExtension: ext.toLowerCase());

        if (state.uploadedStoragePath == null) {
          await for (final progress in repo.uploadFile(
            file: source.file!,
            storagePath: storagePath,
            contentType: source.mimeType,
          )) {
            controller.updateUploadProgress(progress.fraction);
          }
          controller.markStorageUploaded(storagePath);
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
      _started = false;
      if (mounted) controller.fail(e.toString());
    }
  }

  void _retry() {
    ref.read(uploadControllerProvider.notifier).retryProcessing();
    _runUploadAndCreate();
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
                    value: state.uploadFraction == 0
                        ? null
                        : state.uploadFraction,
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
          Semantics(
            liveRegion: true,
            label: '$stepLabel, $pct percent',
            child: Text(
              stepLabel,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
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
                    label: state.uploadedStoragePath == null
                        ? 'Try again'
                        : 'Retry registration',
                    onPressed: _retry,
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
    final docAsync = docId == null
        ? null
        : ref.watch(documentByIdProvider(docId));
    final doc = docAsync?.valueOrNull;
    final extractionJobId = doc?.extractionJobId;
    final jobAsync = extractionJobId == null || extractionJobId.isEmpty
        ? null
        : ref.watch(asyncJobByIdProvider(extractionJobId));
    final job = jobAsync?.valueOrNull;

    final failed =
        doc?.status == DocumentStatus.failed ||
        job?.status == AsyncJobStatus.failed;
    final listenerError =
        docAsync?.hasError == true || jobAsync?.hasError == true;
    final showError = failed || listenerError;
    final ready = doc?.status == DocumentStatus.ready;
    final extractionProgress = job?.progress ?? 0;
    final failureMessage = job?.status == AsyncJobStatus.failed
        ? (job?.errorMessage ?? doc?.errorMessage)
        : doc?.errorMessage;

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
              color: showError ? c.errorSubtle : c.successSubtle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              showError ? Icons.error_outline : Icons.check,
              size: 32,
              color: showError ? c.error : c.success,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            listenerError
                ? 'Couldn’t refresh progress'
                : failed
                ? 'Extraction failed'
                : (ready ? 'All done' : 'Processing...'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            listenerError
                ? 'The status listener stopped. Check your connection and try again.'
                : failed
                ? (failureMessage ?? 'Something went wrong during extraction.')
                : (ready
                      ? 'Your study material is ready.'
                      : extractionProgress > 0
                      ? 'Extracting text… $extractionProgress%'
                      : 'Hang tight — backend is finishing up.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textMuted),
          ),
          if (listenerError) ...[
            const SizedBox(height: Spacing.lg),
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                if (docId != null) {
                  ref.invalidate(documentByIdProvider(docId));
                }
                if (extractionJobId != null && extractionJobId.isNotEmpty) {
                  ref.invalidate(asyncJobByIdProvider(extractionJobId));
                }
              },
            ),
          ],
          const Spacer(),
          if (state.courseId != null)
            AppButton(
              label: 'View in course',
              fullWidth: true,
              onPressed: () {
                ref
                    .read(uploadControllerProvider.notifier)
                    .reset(courseId: state.courseId);
                context.go('/library/${state.courseId}');
              },
            ),
          const SizedBox(height: Spacing.sm),
          AppButton(
            label: 'Upload more',
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => ref
                .read(uploadControllerProvider.notifier)
                .reset(courseId: state.courseId),
          ),
        ],
      ),
    );
  }
}
