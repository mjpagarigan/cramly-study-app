import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
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
        error: (e, _) => Center(
          child: Text('Failed to load document\n$e',
              textAlign: TextAlign.center, style: TextStyle(color: c.error)),
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
        title: const Text('Delete document?'),
        content: Text(
          '"${doc.title}" and its extracted text will be permanently deleted.',
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
    if (confirmed != true) return;

    try {
      await ref.read(documentRepositoryProvider).delete(doc.id);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.document});
  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _Header(document: document),
            const SizedBox(height: Spacing.lg),
            _GenerateActions(document: document),
            const SizedBox(height: Spacing.xl),
            Expanded(child: _ExtractedTextView(document: document)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.document});
  final Document document;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.accentSubtle,
            borderRadius: Radii.cardRadius,
          ),
          alignment: Alignment.center,
          child: Icon(_iconFor(document.sourceType),
              color: c.accent, size: 22),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _statusBadgeFor(document.status),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: Text(
                      _meta(document),
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
    );
  }

  static IconData _iconFor(DocumentSourceType t) => switch (t) {
        DocumentSourceType.pdf => Icons.picture_as_pdf,
        DocumentSourceType.docx => Icons.description,
        DocumentSourceType.pptx => Icons.slideshow,
        DocumentSourceType.image => Icons.image,
        DocumentSourceType.audio => Icons.mic,
        DocumentSourceType.youtube => Icons.play_circle,
        DocumentSourceType.webUrl => Icons.link,
      };

  static Widget _statusBadgeFor(DocumentStatus s) => switch (s) {
        DocumentStatus.ready =>
          const AppBadge(label: 'Ready', color: AppBadgeColor.success),
        DocumentStatus.failed =>
          const AppBadge(label: 'Failed', color: AppBadgeColor.error),
        _ => const AppBadge(label: 'Extracting', color: AppBadgeColor.secondary),
      };

  static String _meta(Document d) {
    final parts = <String>[];
    if (d.pageCount != null) parts.add('${d.pageCount} pages');
    if (d.wordCount > 0) parts.add('${d.wordCount} words');
    return parts.join(' · ');
  }
}

class _GenerateActions extends StatelessWidget {
  const _GenerateActions({required this.document});
  final Document document;

  @override
  Widget build(BuildContext context) {
    // Disabled for Sprint 3 — generators land in Sprints 5/7/9/10. Placeholder
    // surfaces the eventual UI so the user can see what's coming.
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: const [
        _DisabledAction(label: 'Flashcards', sprint: 5, icon: Icons.flash_on),
        _DisabledAction(label: 'Quiz', sprint: 7, icon: Icons.quiz),
        _DisabledAction(label: 'Summary', sprint: 9, icon: Icons.notes),
        _DisabledAction(label: 'Podcast', sprint: 10, icon: Icons.podcasts),
      ],
    );
  }
}

class _DisabledAction extends StatelessWidget {
  const _DisabledAction({
    required this.label,
    required this.sprint,
    required this.icon,
  });
  final String label;
  final int sprint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lands in Sprint $sprint',
      child: AppButton(
        label: label,
        icon: icon,
        size: AppButtonSize.sm,
        variant: AppButtonVariant.secondary,
        // Disabled — onPressed null shows the disabled style.
        onPressed: null,
      ),
    );
  }
}

class _ExtractedTextView extends ConsumerWidget {
  const _ExtractedTextView({required this.document});
  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    if (document.status == DocumentStatus.failed) {
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
              document.errorMessage ?? 'Unknown error.',
              style: TextStyle(fontSize: 13, color: c.textPrimary),
            ),
          ],
        ),
      );
    }

    if (document.status != DocumentStatus.ready ||
        document.extractedTextPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Spacing.md),
            Text(
              'Extracting text...',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
        ),
      );
    }

    final textAsync = ref.watch(extractedTextProvider(document.extractedTextPath!));
    return textAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'Failed to load extracted text: $e',
        style: TextStyle(color: c.error),
      ),
      data: (text) {
        if (text == null || text.isEmpty) {
          return Text(
            '(empty)',
            style: TextStyle(color: c.textMuted),
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
