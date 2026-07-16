import '../courses/data/course_model.dart';
import '../decks/data/deck_model.dart';
import '../documents/data/document_model.dart';
import '../summaries/data/summary_model.dart';

enum HomeRecentKind { course, document, deck, summary }

class HomeNextStep {
  const HomeNextStep({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.location,
  });

  final String title;
  final String description;
  final String actionLabel;
  final String location;
}

class HomeRecentItem {
  const HomeRecentItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.updatedAt,
  });

  final String id;
  final HomeRecentKind kind;
  final String title;
  final String subtitle;
  final String location;
  final DateTime? updatedAt;
}

class HomeDashboardData {
  const HomeDashboardData({required this.nextStep, required this.recent});

  final HomeNextStep nextStep;
  final List<HomeRecentItem> recent;
}

/// Builds the Home dashboard exclusively from persisted user records.
///
/// Streak and due-card values deliberately do not appear here: Cramly does not
/// yet track the review events needed to derive them accurately.
HomeDashboardData deriveHomeDashboard({
  required List<Course> courses,
  required List<Document> documents,
  required List<Deck> decks,
  required List<Summary> summaries,
  int recentLimit = 4,
}) {
  final sortedCourses = [...courses]..sort(_newestCourseFirst);
  final sortedDocuments = [...documents]..sort(_newestDocumentFirst);

  final readyDocument = sortedDocuments
      .where(
        (document) =>
            document.status == DocumentStatus.ready &&
            document.id.isNotEmpty &&
            document.courseId.isNotEmpty,
      )
      .firstOrNull;

  final HomeNextStep nextStep;
  if (readyDocument != null) {
    final course = sortedCourses
        .where((course) => course.id == readyDocument.courseId)
        .firstOrNull;
    nextStep = HomeNextStep(
      title: course == null
          ? 'Continue ${readyDocument.title}'
          : 'Continue ${course.name}',
      description:
          '${readyDocument.title} is ready. Turn it into flashcards or a focused summary.',
      actionLabel: 'Open document',
      location: '/library/${readyDocument.courseId}/doc/${readyDocument.id}',
    );
  } else if (sortedCourses.isNotEmpty) {
    final course = sortedCourses.first;
    nextStep = HomeNextStep(
      title: 'Add material to ${course.name}',
      description:
          'Upload a document, recording, YouTube video, or web article to begin.',
      actionLabel: 'Upload material',
      location: '/upload?courseId=${Uri.encodeQueryComponent(course.id)}',
    );
  } else {
    nextStep = const HomeNextStep(
      title: 'Create your first course',
      description:
          'Organize your material by class, then upload something you want to learn.',
      actionLabel: 'Open Library',
      location: '/library',
    );
  }

  final recent = <HomeRecentItem>[
    for (final course in courses)
      if (course.id.isNotEmpty)
        HomeRecentItem(
          id: course.id,
          kind: HomeRecentKind.course,
          title: course.name,
          subtitle: _courseCounts(course),
          location: '/library/${course.id}',
          updatedAt: course.updatedAt ?? course.createdAt,
        ),
    for (final document in documents)
      if (document.id.isNotEmpty && document.courseId.isNotEmpty)
        HomeRecentItem(
          id: document.id,
          kind: HomeRecentKind.document,
          title: document.title,
          subtitle:
              '${_documentSourceLabel(document.sourceType)} · ${_documentStatusLabel(document.status)}',
          location: '/library/${document.courseId}/doc/${document.id}',
          updatedAt: document.uploadedAt ?? document.extractedAt,
        ),
    for (final deck in decks)
      if (deck.id.isNotEmpty && deck.courseId.isNotEmpty)
        HomeRecentItem(
          id: deck.id,
          kind: HomeRecentKind.deck,
          title: deck.title,
          subtitle:
              '${deck.generationMethod.label} · ${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}',
          location: '/library/${deck.courseId}/deck/${deck.id}',
          updatedAt: deck.updatedAt ?? deck.createdAt,
        ),
    for (final summary in summaries)
      if (summary.id.isNotEmpty &&
          summary.courseId.isNotEmpty &&
          summary.sourceDocumentId.isNotEmpty)
        HomeRecentItem(
          id: summary.id,
          kind: HomeRecentKind.summary,
          title: '${summary.depth.label} summary',
          subtitle: _summaryStatusLabel(summary.status),
          location:
              '/library/${summary.courseId}/doc/${summary.sourceDocumentId}/summary/${summary.id}',
          updatedAt: summary.updatedAt ?? summary.createdAt,
        ),
  ]..sort(_newestRecentFirst);

  return HomeDashboardData(
    nextStep: nextStep,
    recent: recent.take(recentLimit).toList(growable: false),
  );
}

String _courseCounts(Course course) {
  final documents =
      '${course.documentCount} ${course.documentCount == 1 ? 'document' : 'documents'}';
  final decks =
      '${course.deckCount} ${course.deckCount == 1 ? 'deck' : 'decks'}';
  return '$documents · $decks';
}

String _documentSourceLabel(DocumentSourceType type) => switch (type) {
  DocumentSourceType.pdf => 'PDF',
  DocumentSourceType.docx => 'DOCX',
  DocumentSourceType.pptx => 'PPTX',
  DocumentSourceType.markdown => 'Markdown',
  DocumentSourceType.image => 'Image',
  DocumentSourceType.audio => 'Audio',
  DocumentSourceType.youtube => 'YouTube',
  DocumentSourceType.webUrl => 'Web article',
};

String _documentStatusLabel(DocumentStatus status) => switch (status) {
  DocumentStatus.uploading => 'Uploading',
  DocumentStatus.extracting => 'Extracting',
  DocumentStatus.ready => 'Ready',
  DocumentStatus.failed => 'Failed',
};

String _summaryStatusLabel(SummaryStatus status) => switch (status) {
  SummaryStatus.queued => 'Queued',
  SummaryStatus.generating => 'Generating',
  SummaryStatus.ready => 'Ready',
  SummaryStatus.failed => 'Failed',
};

int _newestCourseFirst(Course a, Course b) => _compareNewest(
  a.updatedAt ?? a.createdAt,
  b.updatedAt ?? b.createdAt,
  a.id,
  b.id,
);

int _newestDocumentFirst(Document a, Document b) => _compareNewest(
  a.uploadedAt ?? a.extractedAt,
  b.uploadedAt ?? b.extractedAt,
  a.id,
  b.id,
);

int _newestRecentFirst(HomeRecentItem a, HomeRecentItem b) => _compareNewest(
  a.updatedAt,
  b.updatedAt,
  '${a.kind.name}:${a.id}',
  '${b.kind.name}:${b.id}',
);

int _compareNewest(DateTime? a, DateTime? b, String aId, String bId) {
  if (a == null && b == null) return aId.compareTo(bId);
  if (a == null) return 1;
  if (b == null) return -1;
  final byDate = b.compareTo(a);
  return byDate == 0 ? aId.compareTo(bId) : byDate;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
