import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page_header.dart';
import '../../shared/widgets/learning_trace.dart';
import '../courses/providers/course_providers.dart';
import '../courses/widgets/course_form_sheet.dart';
import '../decks/providers/deck_providers.dart';
import '../documents/providers/document_providers.dart';
import '../summaries/providers/summary_providers.dart';
import 'home_dashboard_data.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final coursesAsync = ref.watch(coursesStreamProvider);
    final documentsAsync = ref.watch(allDocumentsProvider);
    final decksAsync = ref.watch(allDecksProvider);
    final summariesAsync = ref.watch(allSummariesProvider);

    final courses = coursesAsync.valueOrNull;
    final documents = documentsAsync.valueOrNull;
    final decks = decksAsync.valueOrNull;
    final summaries = summariesAsync.valueOrNull;
    final dashboard =
        courses != null &&
            documents != null &&
            decks != null &&
            summaries != null
        ? deriveHomeDashboard(
            courses: courses,
            documents: documents,
            decks: decks,
            summaries: summaries,
          )
        : null;
    final hasError =
        coursesAsync.hasError ||
        documentsAsync.hasError ||
        decksAsync.hasError ||
        summariesAsync.hasError;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Spacing.page,
            Spacing.lg,
            Spacing.page,
            Spacing.xxxl,
          ),
          children: [
            AppPageHeader(
              eyebrow: _today(),
              title: '${_greeting()}, ${_firstName(user)}.',
              subtitle: 'Pick up where your material left off.',
              trailing: _ProfileAvatar(user: user),
            ),
            const SizedBox(height: Spacing.lg),
            const Row(
              children: [
                Expanded(
                  child: _ZeroCard(value: '0', label: 'Current streak'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ZeroCard(value: '0', label: 'Cards due'),
                ),
              ],
            ),
            const _SectionHeading(
              title: 'Your next step',
              detail: 'Based on recent work',
            ),
            _NextStepCard(
              nextStep: dashboard?.nextStep,
              hasError: hasError && dashboard == null,
              onRetry: () => _invalidate(ref),
            ),
            const _SectionHeading(title: 'Quick actions'),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    title: 'Upload material',
                    subtitle: 'Files, audio, YouTube, or web',
                    onTap: () => context.push('/upload'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    title: 'Create a course',
                    subtitle: 'Organize documents and decks',
                    onTap: () => showCourseFormSheet(context),
                  ),
                ),
              ],
            ),
            _SectionHeading(
              title: 'Recent',
              actionLabel: 'See library',
              onAction: () => context.go('/library'),
            ),
            _RecentActivity(
              items: dashboard?.recent,
              hasError: hasError && dashboard == null,
              onRetry: () => _invalidate(ref),
            ),
          ],
        ),
      ),
    );
  }

  static void _invalidate(WidgetRef ref) {
    ref
      ..invalidate(coursesStreamProvider)
      ..invalidate(allDocumentsProvider)
      ..invalidate(allDecksProvider)
      ..invalidate(allSummariesProvider);
  }

  static Future<void> _refresh(WidgetRef ref) async {
    _invalidate(ref);
    try {
      await Future.wait([
        ref.read(coursesStreamProvider.future),
        ref.read(allDocumentsProvider.future),
        ref.read(allDecksProvider.future),
        ref.read(allSummariesProvider.future),
      ]);
    } catch (_) {
      // Each provider exposes its own error state in the dashboard. Completing
      // the gesture normally avoids a second, unhandled refresh exception.
    }
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String _firstName(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }
    final emailName = user?.email?.split('@').first.trim();
    return emailName == null || emailName.isEmpty ? 'there' : emailName;
  }

  static String _today() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${now.day} ${months[now.month - 1]}';
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photoUrl = user?.photoURL?.trim();
    final initials = _initials(user);
    return Semantics(
      button: true,
      label: 'Open profile',
      excludeSemantics: true,
      child: Material(
        color: c.surfaceSoft,
        shape: CircleBorder(side: BorderSide(color: c.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/profile'),
          child: SizedBox.square(
            dimension: 44,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _AvatarInitials(initials: initials),
                  )
                : _AvatarInitials(initials: initials),
          ),
        ),
      ),
    );
  }

  static String _initials(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      return parts.take(2).map((part) => part[0]).join().toUpperCase();
    }
    final email = user?.email?.trim();
    return email == null || email.isEmpty ? 'C' : email[0].toUpperCase();
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppTheme.ui(
          context,
          fontWeight: FontWeight.w700,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

class _ZeroCard extends StatelessWidget {
  const _ZeroCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.surfaceRadius,
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTheme.display(
                context,
                fontSize: 31,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 27, bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                letterSpacing: -0.25,
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.muted),
            ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.nextStep,
    required this.hasError,
    required this.onRetry,
  });

  final HomeNextStep? nextStep;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = hasError
        ? 'Your next step is unavailable'
        : nextStep?.title ?? 'Finding your next step';
    final description = hasError
        ? 'Cramly could not refresh your recent work. Try again.'
        : nextStep?.description ?? 'Checking your latest study material…';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.primaryDeep,
        borderRadius: Radii.surfaceRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LearningTrace(
              width: 240,
              color: const Color(0xFFC5D5CE),
              terminalColor: c.poppy,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTheme.display(
                context,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF4F7F5),
                height: 1.03,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFC5D5CE),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 17),
            if (hasError)
              _InvertedButton(label: 'Try again', onPressed: onRetry)
            else if (nextStep != null)
              _InvertedButton(
                label: nextStep!.actionLabel,
                onPressed: () => context.go(nextStep!.location),
              )
            else
              const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF4F7F5),
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvertedButton extends StatelessWidget {
  const _InvertedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: const Color(0xFFF4F7F5),
        shape: const RoundedRectangleBorder(borderRadius: Radii.controlRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          focusColor: c.poppySubtle,
          child: Center(
            child: Text(
              label,
              style: AppTheme.ui(
                context,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.primaryDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.ui(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.items,
    required this.hasError,
    required this.onRetry,
  });

  final List<HomeRecentItem>? items;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (hasError) {
      return _RecentMessage(
        message: 'Cramly could not load recent work.',
        actionLabel: 'Try again',
        onAction: onRetry,
      );
    }
    if (items == null) {
      return const _RecentMessage(message: 'Loading recent work…');
    }
    if (items!.isEmpty) {
      return const _RecentMessage(
        message:
            'Your courses, documents, decks, and summaries will appear here.',
      );
    }

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.surfaceRadius,
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items!.length; index++) ...[
            _RecentRow(item: items![index]),
            if (index < items!.length - 1) Divider(height: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

class _RecentMessage extends StatelessWidget {
  const _RecentMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: Radii.surfaceRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: c.muted),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item});

  final HomeRecentItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => context.go(item.location),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon(item.kind), size: 20, color: c.primary),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.ui(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: c.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(Icons.chevron_right, size: 20, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(HomeRecentKind kind) => switch (kind) {
    HomeRecentKind.course => Icons.school_outlined,
    HomeRecentKind.document => Icons.description_outlined,
    HomeRecentKind.deck => Icons.style_outlined,
    HomeRecentKind.summary => Icons.summarize_outlined,
  };
}
