import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_page_header.dart';
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
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            AppPageHeader(
              title: 'Library',
              eyebrow: 'Your material',
              showTrace: true,
              trailing: AppButton(
                label: 'New',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.ghost,
                icon: Icons.add,
                onPressed: () => showCourseFormSheet(context),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            AppInput(
              controller: _searchController,
              label: 'Search courses',
              placeholder: 'Search your courses',
              icon: Icons.search,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: Spacing.lg),
            Expanded(
              child: coursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => EmptyState(
                  title: 'Couldn’t load your library',
                  subtitle: 'Check your connection and try again.',
                  icon: Icons.cloud_off_outlined,
                  actionLabel: 'Try again',
                  onAction: () => ref.invalidate(coursesStreamProvider),
                ),
                data: (all) {
                  final filtered = _query.isEmpty
                      ? all
                      : filterCourses(all, _query);

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
                      subtitle:
                          'No course matches “${_searchController.text.trim()}”. Try a different search.',
                      icon: Icons.search_off,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacing.xxxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (_, i) => _CourseRow(course: filtered[i]),
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

List<Course> filterCourses(List<Course> courses, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return List<Course>.of(courses);
  return courses
      .where((course) => course.name.toLowerCase().contains(normalized))
      .toList();
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
          Semantics(
            label: '${course.name} course color',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.28)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
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
    ];
    return parts.join(' · ');
  }
}
