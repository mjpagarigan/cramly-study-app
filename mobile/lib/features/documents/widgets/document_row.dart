import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/document_model.dart';

class DocumentRow extends StatelessWidget {
  const DocumentRow({super.key, required this.document, this.onTap});

  final Document document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 44,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            alignment: Alignment.center,
            child: Icon(_iconFor(document.sourceType), size: 18, color: c.accent),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _subtitle(document),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    _StatusBadge(status: document.status),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: c.textMuted),
        ],
      ),
    );
  }

  IconData _iconFor(DocumentSourceType t) => switch (t) {
        DocumentSourceType.pdf => Icons.picture_as_pdf,
        DocumentSourceType.docx => Icons.description,
        DocumentSourceType.pptx => Icons.slideshow,
        DocumentSourceType.image => Icons.image,
        DocumentSourceType.audio => Icons.mic,
        DocumentSourceType.youtube => Icons.play_circle,
        DocumentSourceType.webUrl => Icons.link,
      };

  String _subtitle(Document d) {
    final parts = <String>[];
    if (d.pageCount != null) {
      parts.add('${d.pageCount} ${d.pageCount == 1 ? 'page' : 'pages'}');
    }
    if (d.wordCount > 0) parts.add('${d.wordCount} words');
    if (parts.isEmpty && d.fileName != null) parts.add(d.fileName!);
    if (parts.isEmpty && d.sourceUrl != null) parts.add(d.sourceUrl!);
    return parts.join(' · ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      DocumentStatus.uploading =>
        const AppBadge(label: 'Uploading', color: AppBadgeColor.secondary),
      DocumentStatus.extracting =>
        const AppBadge(label: 'Extracting', color: AppBadgeColor.secondary),
      DocumentStatus.ready =>
        const AppBadge(label: 'Ready', color: AppBadgeColor.success),
      DocumentStatus.failed =>
        const AppBadge(label: 'Failed', color: AppBadgeColor.error),
    };
  }
}
