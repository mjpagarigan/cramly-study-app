import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../decks/providers/deck_providers.dart';
import '../../decks/widgets/deck_form_sheet.dart';
import '../../decks/widgets/deck_row.dart';
import '../../documents/providers/document_providers.dart';
import '../../documents/widgets/document_row.dart';
import '../data/course_model.dart';
import '../providers/course_providers.dart';
import '../widgets/course_form_sheet.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  static const _tabs = ['Documents', 'Decks', 'Quizzes', 'Podcasts'];
  int _activeTab = 0;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final course = ref.watch(courseByIdProvider(widget.courseId));

    if (course == null) {
      // Either still loading the stream, or the course was just deleted.
      final coursesAsync = ref.watch(coursesStreamProvider);
      return Scaffold(
        appBar: AppBar(),
        body: coursesAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                title: 'Course not found',
                subtitle: 'It may have been deleted.',
                icon: Icons.error_outline,
                actionLabel: 'Back to Library',
                onAction: () => context.pop(),
              ),
      );
    }

    final color = hexToColor(course.color);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showCourseFormSheet(context, existing: course),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline, color: c.error),
            onPressed: _deleting ? null : () => _confirmDelete(course),
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            0,
            Spacing.xl,
            Spacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: Radii.cardRadius,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.documentCount} docs · ${course.deckCount} decks · ${course.quizCount} quizzes',
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              _SegmentedControl(
                tabs: _tabs,
                activeIndex: _activeTab,
                onChange: (i) => setState(() => _activeTab = i),
              ),
              const SizedBox(height: Spacing.xl),
              Expanded(child: _tabBody(context, _activeTab, course.id)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBody(BuildContext context, int tab, String courseId) {
    return switch (tab) {
      0 => _DocumentsTab(courseId: courseId),
      1 => _DecksTab(courseId: courseId),
      2 => const EmptyState(
        title: 'No quizzes yet',
        subtitle: 'Generate practice exams from a document. Lands in Sprint 7.',
        icon: Icons.quiz_outlined,
      ),
      _ => const EmptyState(
        title: 'No podcasts yet',
        subtitle:
            'Two-speaker AI podcasts generated from your material. Lands in Sprint 10.',
        icon: Icons.podcasts_outlined,
      ),
    };
  }

  Future<void> _confirmDelete(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
          '"${course.name}" and everything inside it will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final ok = await ref
        .read(courseControllerProvider.notifier)
        .delete(course.id);
    if (!mounted) return;

    if (ok) {
      context.pop();
    } else {
      setState(() => _deleting = false);
      final err = ref.read(courseControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${err ?? 'unknown error'}')),
      );
    }
  }
}

class _DecksTab extends ConsumerWidget {
  const _DecksTab({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksByCourseProvider(courseId));

    return decksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load decks: $e',
          style: TextStyle(color: context.colors.error),
        ),
      ),
      data: (decks) {
        if (decks.isEmpty) {
          return EmptyState(
            title: 'No decks yet',
            subtitle:
                'Generate flashcards from a document, or create a manual deck.',
            icon: Icons.style_outlined,
            actionLabel: 'New deck',
            onAction: () => showDeckFormSheet(context, courseId: courseId),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'New deck',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  icon: Icons.add,
                  onPressed: () =>
                      showDeckFormSheet(context, courseId: courseId),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: decks.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
                itemBuilder: (_, i) => DeckRow(
                  deck: decks[i],
                  onTap: () =>
                      context.push('/library/$courseId/deck/${decks[i].id}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.tabs,
    required this.activeIndex,
    required this.onChange,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: Radii.buttonRadius,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: activeIndex == i ? c.accent : Colors.transparent,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Radii.sm),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: activeIndex == i
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: activeIndex == i ? c.textOnAccent : c.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsByCourseProvider(courseId));

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load documents: $e',
          style: TextStyle(color: context.colors.error),
        ),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return EmptyState(
            title: 'No documents yet',
            subtitle:
                'Upload PDFs, slides, lecture notes, audio, or paste a YouTube/web URL.',
            icon: Icons.upload_file_outlined,
            actionLabel: 'Upload',
            onAction: () => context.push('/upload?courseId=$courseId'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Upload',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  icon: Icons.add,
                  onPressed: () => context.push('/upload?courseId=$courseId'),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
                itemBuilder: (_, i) => DocumentRow(
                  document: docs[i],
                  onTap: () =>
                      context.push('/library/$courseId/doc/${docs[i].id}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
