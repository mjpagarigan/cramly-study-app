import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/learning_trace.dart';
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
        title: const Text('Course'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Course actions',
            enabled: !_deleting,
            onSelected: (value) {
              if (value == 'edit') {
                showCourseFormSheet(context, existing: course);
              } else if (value == 'delete') {
                _confirmDelete(course);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit course'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: c.error),
                  title: Text(
                    'Delete course record',
                    style: TextStyle(color: c.error),
                  ),
                ),
              ),
            ],
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
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
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
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: c.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            '${course.documentCount} ${course.documentCount == 1 ? 'document' : 'documents'} · ${course.deckCount} ${course.deckCount == 1 ? 'deck' : 'decks'}',
                            style: TextStyle(fontSize: 13, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.sm),
              const LearningTrace(width: 112, height: 20),
              const SizedBox(height: Spacing.xl),
              _SegmentedControl(
                tabs: _tabs,
                activeIndex: _activeTab,
                onChange: (i) => setState(() => _activeTab = i),
                disabledIndices: const {2, 3},
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
        subtitle:
            'Practice quizzes are planned, but they are not available yet.',
        icon: Icons.quiz_outlined,
      ),
      _ => const EmptyState(
        title: 'No podcasts yet',
        subtitle:
            'Audio study podcasts are planned, but they are not available yet.',
        icon: Icons.podcasts_outlined,
      ),
    };
  }

  Future<void> _confirmDelete(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course record?'),
        content: Text(
          'Only the “${course.name}” course record will be removed. Existing documents, decks, summaries, and uploaded files are not deleted automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete record'),
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
      error: (_, _) => EmptyState(
        title: 'Couldn’t load decks',
        subtitle: 'Check your connection and try again.',
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(decksByCourseProvider(courseId)),
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
    this.disabledIndices = const {},
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChange;
  final Set<int> disabledIndices;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: Radii.buttonRadius,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: Tooltip(
                message: disabledIndices.contains(i)
                    ? '${tabs[i]} are planned but not available yet'
                    : '${tabs[i]} tab',
                child: Semantics(
                  button: true,
                  enabled: !disabledIndices.contains(i),
                  selected: activeIndex == i,
                  label: disabledIndices.contains(i)
                      ? '${tabs[i]} tab, planned and unavailable'
                      : '${tabs[i]} tab',
                  child: InkWell(
                    onTap: disabledIndices.contains(i)
                        ? null
                        : () => onChange(i),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Radii.sm),
                    ),
                    child: AnimatedContainer(
                      duration: context.reduceMotion
                          ? Duration.zero
                          : AppDurations.fast,
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: activeIndex == i ? c.accent : Colors.transparent,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(Radii.sm),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tabs[i],
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: activeIndex == i
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: activeIndex == i
                                  ? c.textOnAccent
                                  : c.textMuted,
                            ),
                          ),
                          if (disabledIndices.contains(i))
                            Text(
                              'Planned',
                              style: TextStyle(fontSize: 9, color: c.textMuted),
                            ),
                        ],
                      ),
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
      error: (_, _) => EmptyState(
        title: 'Couldn’t load documents',
        subtitle: 'Check your connection and try again.',
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(documentsByCourseProvider(courseId)),
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
