import 'package:cramly/core/auth/auth_providers.dart';
import 'package:cramly/core/theme/app_theme.dart';
import 'package:cramly/features/courses/data/course_model.dart';
import 'package:cramly/features/courses/providers/course_providers.dart';
import 'package:cramly/features/decks/data/deck_model.dart';
import 'package:cramly/features/decks/providers/deck_providers.dart';
import 'package:cramly/features/documents/data/document_model.dart';
import 'package:cramly/features/documents/providers/document_providers.dart';
import 'package:cramly/features/home/home_screen.dart';
import 'package:cramly/features/progress/progress_screen.dart';
import 'package:cramly/features/study/study_screen.dart';
import 'package:cramly/features/summaries/data/summary_model.dart';
import 'package:cramly/features/summaries/providers/summary_providers.dart';
import 'package:cramly/shared/widgets/learning_trace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final course = Course(
    id: 'biology',
    name: 'Cell Biology',
    color: '#477966',
    documentCount: 1,
    deckCount: 1,
    updatedAt: DateTime.utc(2026, 7, 14),
  );
  final document = Document(
    id: 'document',
    courseId: course.id,
    sourceType: DocumentSourceType.pdf,
    title: 'Cell respiration',
    status: DocumentStatus.ready,
    uploadedAt: DateTime.utc(2026, 7, 14),
  );
  final deck = Deck(
    id: 'deck',
    courseId: course.id,
    title: 'Cell respiration deck',
    description: '',
    cardCount: 12,
    generationMethod: DeckGenerationMethod.ai,
    status: DeckStatus.ready,
    updatedAt: DateTime.utc(2026, 7, 14),
  );
  final summary = Summary(
    id: 'summary',
    courseId: course.id,
    sourceDocumentId: document.id,
    depth: SummaryDepth.detailed,
    status: SummaryStatus.ready,
    content: '# Cell respiration',
    updatedAt: DateTime.utc(2026, 7, 14),
  );

  testWidgets('Home uses real work while keeping unsupported metrics at zero', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      _testApp(
        child: const HomeScreen(),
        courses: [course],
        documents: [document],
        decks: [deck],
        summaries: [summary],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Cards due'), findsOneWidget);
    expect(find.text('Continue Cell Biology'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cell respiration deck'), 280);
    expect(find.text('Cell respiration deck'), findsOneWidget);
    expect(find.byType(LearningTrace), findsOneWidget);
  });

  testWidgets('Study launches only the real reviewable deck', (tester) async {
    _useMobileViewport(tester);
    final pendingDeck = Deck(
      id: 'pending',
      courseId: course.id,
      title: 'Still generating',
      description: '',
      cardCount: 12,
      generationMethod: DeckGenerationMethod.ai,
      status: DeckStatus.generating,
      updatedAt: DateTime.utc(2026, 7, 15),
    );
    await tester.pumpWidget(
      _testApp(
        child: const StudyScreen(),
        courses: [course],
        documents: [document],
        decks: [pendingDeck, deck],
        summaries: [summary],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cell respiration deck'), findsNWidgets(2));
    expect(find.text('Review deck'), findsOneWidget);
    expect(find.text('Still generating'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('not active in this build'),
      280,
    );
    expect(find.textContaining('not active in this build'), findsOneWidget);
    expect(find.byType(LearningTrace), findsOneWidget);
  });

  testWidgets('Progress reports record counts and no fabricated sessions', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      _testApp(
        child: const ProgressScreen(),
        courses: [course],
        documents: [document],
        decks: [deck],
        summaries: [summary],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Decks created'), findsOneWidget);
    expect(find.text('Summaries generated'), findsOneWidget);
    expect(find.text('Tracked review sessions'), findsOneWidget);
    expect(find.text('Not active'), findsOneWidget);
    expect(find.byType(LearningTrace), findsOneWidget);
  });
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _testApp({
  required Widget child,
  required List<Course> courses,
  required List<Document> documents,
  required List<Deck> decks,
  required List<Summary> summaries,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(null),
      coursesStreamProvider.overrideWith((ref) => Stream.value(courses)),
      allDocumentsProvider.overrideWith((ref) => Stream.value(documents)),
      allDecksProvider.overrideWith((ref) => Stream.value(decks)),
      allSummariesProvider.overrideWith((ref) => Stream.value(summaries)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}
