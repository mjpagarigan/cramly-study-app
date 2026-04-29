import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../jobs/providers/job_providers.dart';
import '../data/summary_model.dart';
import '../providers/summary_providers.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.summaryId});

  final String summaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryByIdProvider(summaryId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Summary'),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load summary\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.error),
          ),
        ),
        data: (summary) {
          if (summary == null) {
            return const EmptyState(
              title: 'Summary not found',
              subtitle: 'It may have been deleted or not created yet.',
              icon: Icons.notes_outlined,
            );
          }
          return _Body(summary: summary);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final jobAsync = summary.jobId == null || summary.jobId!.isEmpty
        ? null
        : ref.watch(asyncJobByIdProvider(summary.jobId!));
    final job = jobAsync?.valueOrNull;

    return SafeArea(
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: c.accentSubtle,
                      borderRadius: Radii.cardRadius,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.notes, color: c.accent, size: 22),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.depth.label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _statusLine(summary, job),
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Expanded(
              child: switch (summary.status) {
                SummaryStatus.failed => _FailedState(summary: summary),
                SummaryStatus.ready => _ReadyState(summary: summary),
                _ => _PendingState(summary: summary, progress: job?.progress ?? 0),
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLine(Summary summary, dynamic job) {
    final progress = job?.progress as int? ?? 0;
    return switch (summary.status) {
      SummaryStatus.ready => 'Ready to read',
      SummaryStatus.failed => 'Generation failed',
      SummaryStatus.generating => progress > 0
          ? 'Generating... $progress%'
          : 'Generating...',
      SummaryStatus.queued => progress > 0 ? 'Queued... $progress%' : 'Queued',
    };
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState({required this.summary, required this.progress});

  final Summary summary;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = progress <= 0 ? null : progress / 100;

    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                color: c.accent,
                backgroundColor: c.border,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              summary.status == SummaryStatus.generating
                  ? 'Writing your summary'
                  : 'Summary queued',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              progress > 0
                  ? 'Current progress: $progress%'
                  : 'The worker will pick this up automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      borderColor: c.error.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Summary generation failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.error,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            summary.errorMessage ?? 'Unknown error.',
            style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ReadyState extends StatelessWidget {
  const _ReadyState({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.content.trim().isEmpty) {
      return const EmptyState(
        title: 'Empty summary',
        subtitle: 'The generator finished but returned no readable content.',
        icon: Icons.notes_outlined,
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SelectionArea(
            child: _MarkdownBlocks(content: summary.content),
          ),
        ),
      ),
    );
  }
}

class _MarkdownBlocks extends StatelessWidget {
  const _MarkdownBlocks({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) _line(context, line),
      ],
    );
  }

  Widget _line(BuildContext context, String line) {
    final c = context.colors;
    final trimmed = line.trimRight();

    if (trimmed.isEmpty) {
      return const SizedBox(height: Spacing.sm);
    }
    if (trimmed.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(
          trimmed.substring(2),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      );
    }
    if (trimmed.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
        child: Text(
          trimmed.substring(3),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      );
    }
    if (trimmed.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.xs),
        child: Text(
          trimmed.substring(4),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      );
    }
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '•',
                style: TextStyle(color: c.accent, fontSize: 16),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                trimmed.substring(2),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        trimmed,
        style: TextStyle(
          fontSize: 14,
          height: 1.7,
          color: c.textPrimary,
        ),
      ),
    );
  }
}
