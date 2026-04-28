import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/course_model.dart';
import '../providers/course_providers.dart';
import '../widgets/course_form_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final coursesAsync = ref.watch(coursesStreamProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.lg,
          Spacing.xl,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Library',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                AppButton(
                  label: 'New',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  icon: Icons.add,
                  onPressed: () => showCourseFormSheet(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            AppInput(
              placeholder: 'Search courses...',
              icon: Icons.search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: Spacing.lg),
            Expanded(
              child: coursesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load courses\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.error),
                  ),
                ),
                data: (all) {
                  final filtered = _query.isEmpty
                      ? all
                      : all
                          .where((x) => x.name.toLowerCase().contains(_query))
                          .toList();

                  if (all.isEmpty) {
                    return EmptyState(
                      title: 'No courses yet',
                      subtitle:
                          'Create your first course to start uploading documents and generating study material.',
                      actionLabel: 'New course',
                      icon: Icons.school_outlined,
                      onAction: () => showCourseFormSheet(context),
                    );
                  }

                  if (filtered.isEmpty) {
                    return EmptyState(
                      title: 'No matches',
                      subtitle: 'Nothing matches "$_query".',
                      icon: Icons.search_off,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacing.xxxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (_, i) =>
                        _CourseRow(course: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = hexToColor(course.color);

    return AppCard(
      onTap: () => context.push('/library/${course.id}'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: Radii.cardRadius,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _summary(course),
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: c.textMuted),
        ],
      ),
    );
  }

  String _summary(Course c) {
    final parts = <String>[
      '${c.documentCount} ${c.documentCount == 1 ? 'doc' : 'docs'}',
      '${c.deckCount} ${c.deckCount == 1 ? 'deck' : 'decks'}',
      '${c.quizCount} ${c.quizCount == 1 ? 'quiz' : 'quizzes'}',
    ];
    return parts.join(' · ');
  }
}
