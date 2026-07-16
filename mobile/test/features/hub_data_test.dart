import 'dart:convert';

import 'package:cramly/features/courses/data/course_model.dart';
import 'package:cramly/features/decks/data/deck_model.dart';
import 'package:cramly/features/documents/data/document_model.dart';
import 'package:cramly/features/documents/data/document_repository.dart';
import 'package:cramly/features/home/home_dashboard_data.dart';
import 'package:cramly/features/progress/progress_data.dart';
import 'package:cramly/features/study/study_hub_data.dart';
import 'package:cramly/features/summaries/data/summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home dashboard data', () {
    test('uses the newest ready document for the next step', () {
      final older = DateTime.utc(2026, 7, 13);
      final newer = DateTime.utc(2026, 7, 14);
      final data = deriveHomeDashboard(
        courses: [
          Course(
            id: 'biology',
            name: 'Cell Biology',
            color: '#477966',
            updatedAt: older,
          ),
        ],
        documents: [
          Document(
            id: 'extracting',
            courseId: 'biology',
            sourceType: DocumentSourceType.pdf,
            title: 'New but not ready',
            status: DocumentStatus.extracting,
            uploadedAt: newer,
          ),
          Document(
            id: 'ready',
            courseId: 'biology',
            sourceType: DocumentSourceType.pdf,
            title: 'Cell respiration',
            status: DocumentStatus.ready,
            uploadedAt: older,
          ),
        ],
        decks: const [],
        summaries: const [],
      );

      expect(data.nextStep.title, 'Continue Cell Biology');
      expect(data.nextStep.location, '/library/biology/doc/ready');
      expect(data.nextStep.actionLabel, 'Open document');
    });

    test('falls back to the latest course and then onboarding', () {
      final data = deriveHomeDashboard(
        courses: [
          Course(
            id: 'older',
            name: 'Older course',
            color: '#24594b',
            updatedAt: DateTime.utc(2026, 7, 12),
          ),
          Course(
            id: 'latest',
            name: 'Organic Chemistry',
            color: '#24594b',
            updatedAt: DateTime.utc(2026, 7, 14),
          ),
        ],
        documents: const [],
        decks: const [],
        summaries: const [],
      );

      expect(data.nextStep.title, 'Add material to Organic Chemistry');
      expect(data.nextStep.location, '/upload?courseId=latest');

      final empty = deriveHomeDashboard(
        courses: const [],
        documents: const [],
        decks: const [],
        summaries: const [],
      );
      expect(empty.nextStep.title, 'Create your first course');
      expect(empty.nextStep.location, '/library');
    });

    test('recent activity is real, navigable, and ordered by date', () {
      final data = deriveHomeDashboard(
        recentLimit: 3,
        courses: [
          Course(
            id: 'course',
            name: 'Biology',
            color: '#477966',
            updatedAt: DateTime.utc(2026, 7, 10),
          ),
        ],
        documents: [
          Document(
            id: 'document',
            courseId: 'course',
            sourceType: DocumentSourceType.pdf,
            title: 'Respiration',
            status: DocumentStatus.ready,
            uploadedAt: DateTime.utc(2026, 7, 11),
          ),
        ],
        decks: [
          Deck(
            id: 'deck',
            courseId: 'course',
            title: 'Respiration deck',
            description: '',
            cardCount: 12,
            generationMethod: DeckGenerationMethod.ai,
            status: DeckStatus.ready,
            updatedAt: DateTime.utc(2026, 7, 12),
          ),
        ],
        summaries: [
          Summary(
            id: 'summary',
            courseId: 'course',
            sourceDocumentId: 'document',
            depth: SummaryDepth.detailed,
            status: SummaryStatus.ready,
            content: '# Summary',
            updatedAt: DateTime.utc(2026, 7, 13),
          ),
        ],
      );

      expect(data.recent.map((item) => item.kind), [
        HomeRecentKind.summary,
        HomeRecentKind.deck,
        HomeRecentKind.document,
      ]);
      expect(
        data.recent.first.location,
        '/library/course/doc/document/summary/summary',
      );
    });
  });

  group('Study hub data', () {
    test('selects only a ready, non-empty deck for review', () {
      final data = deriveStudyHub([
        Deck(
          id: 'generating',
          courseId: 'course',
          title: 'Generating',
          description: '',
          cardCount: 12,
          generationMethod: DeckGenerationMethod.ai,
          status: DeckStatus.generating,
          updatedAt: DateTime.utc(2026, 7, 14),
        ),
        Deck(
          id: 'empty',
          courseId: 'course',
          title: 'Empty',
          description: '',
          cardCount: 0,
          generationMethod: DeckGenerationMethod.manual,
          status: DeckStatus.ready,
          updatedAt: DateTime.utc(2026, 7, 13),
        ),
        Deck(
          id: 'reviewable',
          courseId: 'course',
          title: 'Reviewable',
          description: '',
          cardCount: 8,
          generationMethod: DeckGenerationMethod.manual,
          status: DeckStatus.ready,
          updatedAt: DateTime.utc(2026, 7, 12),
        ),
      ]);

      expect(data.decks.map((deck) => deck.id), [
        'generating',
        'empty',
        'reviewable',
      ]);
      expect(data.featuredDeck?.id, 'reviewable');
      expect(isDeckReviewable(data.decks[0]), isFalse);
      expect(isDeckReviewable(data.decks[1]), isFalse);
    });
  });

  test('Progress reports record counts without review analytics', () {
    final data = deriveProgressData(
      decks: [
        const Deck(
          id: 'deck',
          courseId: 'course',
          title: 'Deck',
          description: '',
          cardCount: 0,
          generationMethod: DeckGenerationMethod.manual,
          status: DeckStatus.ready,
        ),
      ],
      summaries: [
        const Summary(
          id: 'summary',
          courseId: 'course',
          sourceDocumentId: 'document',
          depth: SummaryDepth.tldr,
          status: SummaryStatus.ready,
          content: '',
        ),
      ],
    );

    expect(data.deckCount, 1);
    expect(data.summaryCount, 1);
    expect(data.trackedReviewSessions, 'Not active');
  });

  group('Extracted text decoding', () {
    test('decodes UTF-8 content without losing non-ASCII text', () {
      const source = 'Cramly — café 📚';
      expect(decodeExtractedText(utf8.encode(source)), source);
    });

    test('keeps an empty object distinct from malformed UTF-8', () {
      expect(decodeExtractedText(const []), isEmpty);
      expect(
        () => decodeExtractedText(const [0xC3, 0x28]),
        throwsFormatException,
      );
    });
  });
}
