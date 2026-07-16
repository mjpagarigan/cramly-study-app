import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_sheet_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/learning_trace.dart';
import '../../decks/providers/deck_providers.dart';
import '../../jobs/data/async_job_model.dart';
import '../../jobs/providers/job_providers.dart';
import '../../summaries/data/summary_model.dart';
import '../../summaries/providers/summary_providers.dart';
import '../data/document_model.dart';
import '../providers/document_providers.dart';

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final docAsync = ref.watch(documentByIdProvider(documentId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Document'),
        actions: [
          docAsync.maybeWhen(
            data: (doc) => doc == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, color: c.error),
                    onPressed: () => _confirmDelete(context, ref, doc),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: docAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          title: 'Couldn’t load this document',
          subtitle: 'Check your connection and try again.',
          icon: Icons.cloud_off_outlined,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(documentByIdProvider(documentId)),
        ),
        data: (doc) {
          if (doc == null) {
            return const EmptyState(
              title: 'Document not found',
              subtitle: 'It may have been deleted.',
              icon: Icons.error_outline,
            );
          }
          return _Body(document: doc);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Document doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document record?'),
        content: Text(
          '“${doc.title}”, its uploaded source, and extracted text will be deleted. Generated decks and summaries are retained and may become orphaned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete document'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(documentRepositoryProvider).delete(doc.id);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.document});
  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync =
        document.extractionJobId == null || document.extractionJobId!.isEmpty
        ? null
        : ref.watch(asyncJobByIdProvider(document.extractionJobId!));
    final job = jobAsync?.valueOrNull;
    final jobFailed = job?.status == AsyncJobStatus.failed;
    final effectiveStatus = jobFailed ? DocumentStatus.failed : document.status;
    final effectiveError = jobFailed
        ? (job?.errorMessage ?? document.errorMessage)
        : document.errorMessage;

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
            _Header(
              document: document,
              status: effectiveStatus,
              progress: job?.progress ?? 0,
            ),
            const SizedBox(height: Spacing.sm),
            const LearningTrace(width: 112, height: 20),
            const SizedBox(height: Spacing.lg),
            _GenerateActions(
              document: document,
              effectiveStatus: effectiveStatus,
            ),
            const SizedBox(height: Spacing.xl),
            Expanded(
              child: jobAsync?.hasError == true
                  ? EmptyState(
                      title: 'Couldn’t check extraction status',
                      subtitle:
                          'The status listener stopped. Check your connection and try again.',
                      icon: Icons.cloud_off_outlined,
                      actionLabel: 'Try again',
                      onAction: () => ref.invalidate(
                        asyncJobByIdProvider(document.extractionJobId!),
                      ),
                    )
                  : _ExtractedTextView(
                      document: document,
                      status: effectiveStatus,
                      errorMessage: effectiveError,
                      progress: job?.progress ?? 0,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.document,
    required this.status,
    required this.progress,
  });
  final Document document;
  final DocumentStatus status;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              _iconFor(document.sourceType),
              color: c.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _statusBadgeFor(status),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Text(
                        _meta(document, status, progress),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(DocumentSourceType t) => switch (t) {
    DocumentSourceType.pdf => Icons.picture_as_pdf,
    DocumentSourceType.docx => Icons.description,
    DocumentSourceType.pptx => Icons.slideshow,
    DocumentSourceType.markdown => Icons.notes,
    DocumentSourceType.image => Icons.image,
    DocumentSourceType.audio => Icons.mic,
    DocumentSourceType.youtube => Icons.play_circle,
    DocumentSourceType.webUrl => Icons.link,
  };

  static Widget _statusBadgeFor(DocumentStatus s) => switch (s) {
    DocumentStatus.ready => const AppBadge(
      label: 'Ready',
      color: AppBadgeColor.success,
    ),
    DocumentStatus.failed => const AppBadge(
      label: 'Failed',
      color: AppBadgeColor.error,
    ),
    DocumentStatus.uploading => const AppBadge(
      label: 'Uploading',
      color: AppBadgeColor.secondary,
    ),
    DocumentStatus.extracting => const AppBadge(
      label: 'Extracting',
      color: AppBadgeColor.secondary,
    ),
  };

  static String _meta(Document d, DocumentStatus status, int progress) {
    final parts = <String>[];
    if (d.pageCount != null) parts.add('${d.pageCount} pages');
    if (d.wordCount > 0) parts.add('${d.wordCount} words');
    if ((status == DocumentStatus.uploading ||
            status == DocumentStatus.extracting) &&
        progress > 0) {
      parts.add('$progress%');
    }
    return parts.join(' · ');
  }
}

class _GenerateActions extends ConsumerStatefulWidget {
  const _GenerateActions({
    required this.document,
    required this.effectiveStatus,
  });
  final Document document;
  final DocumentStatus effectiveStatus;

  @override
  ConsumerState<_GenerateActions> createState() => _GenerateActionsState();
}

class _GenerateActionsState extends ConsumerState<_GenerateActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final latestDeckId = document.generatedAssets.deckIds.isEmpty
        ? null
        : document.generatedAssets.deckIds.last;
    final latestSummaryId = document.generatedAssets.summaryIds.isEmpty
        ? null
        : document.generatedAssets.summaryIds.last;
    final canGenerateFlashcards =
        widget.effectiveStatus == DocumentStatus.ready;
    final canGenerateSummary = widget.effectiveStatus == DocumentStatus.ready;

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        Tooltip(
          message: canGenerateFlashcards
              ? 'Generate a flashcard deck'
              : widget.effectiveStatus == DocumentStatus.failed
              ? 'Fix extraction first'
              : 'Wait for extraction to finish',
          child: AppButton(
            label: 'Flashcards',
            icon: Icons.flash_on,
            size: AppButtonSize.sm,
            variant: AppButtonVariant.secondary,
            busy: _busy,
            onPressed: canGenerateFlashcards && !_busy
                ? () => _generateFlashcards(document)
                : null,
          ),
        ),
        if (latestDeckId != null)
          AppButton(
            label: 'Latest deck',
            icon: Icons.style_outlined,
            size: AppButtonSize.sm,
            variant: AppButtonVariant.ghost,
            onPressed: () => context.push(
              '/library/${document.courseId}/deck/$latestDeckId',
            ),
          ),
        const _DisabledAction(label: 'Quiz', icon: Icons.quiz),
        Tooltip(
          message: canGenerateSummary
              ? 'Generate a markdown summary'
              : widget.effectiveStatus == DocumentStatus.failed
              ? 'Fix extraction first'
              : 'Wait for extraction to finish',
          child: AppButton(
            label: 'Summary',
            icon: Icons.notes,
            size: AppButtonSize.sm,
            variant: AppButtonVariant.secondary,
            busy: _busy,
            onPressed: canGenerateSummary && !_busy
                ? () => _generateSummary(document)
                : null,
          ),
        ),
        if (latestSummaryId != null)
          AppButton(
            label: 'Latest summary',
            icon: Icons.auto_stories,
            size: AppButtonSize.sm,
            variant: AppButtonVariant.ghost,
            onPressed: () => context.push(
              '/library/${document.courseId}/doc/${document.id}/summary/$latestSummaryId',
            ),
          ),
        const _DisabledAction(label: 'Podcast', icon: Icons.podcasts),
      ],
    );
  }

  Future<void> _generateSummary(Document document) async {
    final depth = await showModalBottomSheet<SummaryDepth>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: Radii.sheetRadius),
      builder: (_) => const _SummaryDepthSheet(),
    );
    if (depth == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(summaryRepositoryProvider)
          .generateSummary(documentId: document.id, depth: depth);
      if (!mounted) return;
      context.push(
        '/library/${document.courseId}/doc/${document.id}/summary/${result.summary.id}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start summary generation: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateFlashcards(Document document) async {
    final cardCount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: Radii.sheetRadius),
      builder: (_) => const _FlashcardCountSheet(),
    );
    if (cardCount == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(deckRepositoryProvider)
          .generateDeck(documentId: document.id, cardCount: cardCount);
      if (!mounted) return;
      context.push('/library/${document.courseId}/deck/${result.deck.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start flashcard generation: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SummaryDepthSheet extends StatelessWidget {
  const _SummaryDepthSheet();

  @override
  Widget build(BuildContext context) {
    return BottomSheetShell(
      title: 'Choose summary depth',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final depth in SummaryDepth.values) ...[
            _DepthOption(depth: depth),
            if (depth != SummaryDepth.values.last)
              const SizedBox(height: Spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _DepthOption extends StatelessWidget {
  const _DepthOption({required this.depth});
  final SummaryDepth depth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: () => Navigator.of(context).pop(depth),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: Radii.cardRadius,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.notes, color: c.accent, size: 18),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  depth.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  depth.description,
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: c.textMuted),
        ],
      ),
    );
  }
}

class _FlashcardCountSheet extends StatelessWidget {
  const _FlashcardCountSheet();

  @override
  Widget build(BuildContext context) {
    return BottomSheetShell(
      title: 'Choose deck size',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _CardCountOption(
            count: 8,
            title: 'Quick set',
            subtitle: 'Fast pass over the biggest concepts.',
          ),
          SizedBox(height: Spacing.sm),
          _CardCountOption(
            count: 12,
            title: 'Balanced set',
            subtitle: 'Good default coverage for most documents.',
          ),
          SizedBox(height: Spacing.sm),
          _CardCountOption(
            count: 16,
            title: 'Deeper set',
            subtitle: 'More coverage when the material is dense.',
          ),
        ],
      ),
    );
  }
}

class _CardCountOption extends StatelessWidget {
  const _CardCountOption({
    required this.count,
    required this.title,
    required this.subtitle,
  });

  final int count;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: () => Navigator.of(context).pop(count),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: Radii.cardRadius,
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.accent,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: c.textMuted),
        ],
      ),
    );
  }
}

class _DisabledAction extends StatelessWidget {
  const _DisabledAction({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label generation is planned but not available yet',
      child: AppButton(
        label: label,
        icon: icon,
        size: AppButtonSize.sm,
        variant: AppButtonVariant.secondary,
        onPressed: null,
      ),
    );
  }
}

class _ExtractedTextView extends ConsumerWidget {
  const _ExtractedTextView({
    required this.document,
    required this.status,
    required this.errorMessage,
    required this.progress,
  });
  final Document document;
  final DocumentStatus status;
  final String? errorMessage;
  final int progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    if (status == DocumentStatus.failed) {
      return AppCard(
        borderColor: c.error.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extraction failed',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage ?? 'Unknown error.',
              style: TextStyle(fontSize: 13, color: c.textPrimary),
            ),
          ],
        ),
      );
    }

    if (status != DocumentStatus.ready) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Spacing.md),
            Text(
              progress > 0 ? 'Extracting text… $progress%' : 'Extracting text…',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
        ),
      );
    }

    if (document.extractedTextPath == null) {
      return SingleChildScrollView(
        child: AppCard(
          borderColor: c.warning.withValues(alpha: 0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.text_snippet_outlined, color: c.warning),
              const SizedBox(height: Spacing.sm),
              Text(
                'Extracted text is not available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textPrimary),
              ),
              const SizedBox(height: Spacing.md),
              AppButton(
                label: 'Check again',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    ref.invalidate(documentByIdProvider(document.id)),
              ),
            ],
          ),
        ),
      );
    }

    final textAsync = ref.watch(
      extractedTextProvider(document.extractedTextPath!),
    );
    return textAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppCard(
        borderColor: c.error.withValues(alpha: 0.35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: c.error),
            const SizedBox(height: Spacing.sm),
            Text(
              'Couldn’t load extracted text',
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
            const SizedBox(height: Spacing.md),
            AppButton(
              label: 'Retry download',
              size: AppButtonSize.sm,
              onPressed: () => ref.invalidate(
                extractedTextProvider(document.extractedTextPath!),
              ),
            ),
          ],
        ),
      ),
      data: (text) {
        if (text == null) {
          return const EmptyState(
            title: 'Text is not ready',
            subtitle: 'Check again in a moment.',
            icon: Icons.text_snippet_outlined,
          );
        }
        if (text.trim().isEmpty) {
          return const EmptyState(
            title: 'No readable text',
            subtitle:
                'The extraction completed successfully, but the result was empty.',
            icon: Icons.text_snippet_outlined,
          );
        }
        return AppCard(
          padding: const EdgeInsets.all(Spacing.md),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
