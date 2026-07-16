import 'package:cramly/core/theme/app_theme.dart';
import 'package:cramly/features/courses/data/course_model.dart';
import 'package:cramly/features/courses/providers/course_providers.dart';
import 'package:cramly/features/courses/screens/course_detail_screen.dart';
import 'package:cramly/features/courses/screens/library_screen.dart';
import 'package:cramly/features/courses/widgets/course_form_sheet.dart';
import 'package:cramly/features/documents/data/document_model.dart';
import 'package:cramly/features/documents/providers/document_providers.dart';
import 'package:cramly/features/documents/screens/document_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const course = Course(
    id: 'course-1',
    name: 'Organic Chemistry',
    color: '#477966',
    documentCount: 1,
    deckCount: 2,
  );

  test('course search is case-insensitive and trims the query', () {
    const courses = [
      course,
      Course(id: 'course-2', name: 'Cell Biology', color: '#486F91'),
    ];

    expect(filterCourses(courses, '  CHEM '), [course]);
    expect(filterCourses(courses, ''), hasLength(2));
    expect(filterCourses(courses, 'physics'), isEmpty);
  });

  testWidgets('course form labels validation and exposes accessible colors', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const _CourseFormLauncher(),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    expect(find.text('Course name'), findsOneWidget);
    expect(find.bySemanticsLabel('Course color #477966'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('course deletion copy is explicitly non-cascading', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursesStreamProvider.overrideWith(
            (ref) => Stream.value(const [course]),
          ),
          documentsByCourseProvider.overrideWith(
            (ref, id) => Stream.value(const <Document>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CourseDetailScreen(courseId: 'course-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Course actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete course record'));
    await tester.pumpAndSettle();

    expect(find.text('Delete course record?'), findsOneWidget);
    expect(
      find.textContaining('Only the “Organic Chemistry” course record'),
      findsOneWidget,
    );
    expect(
      find.textContaining('are not deleted automatically'),
      findsOneWidget,
    );
  });

  testWidgets('document deletion warns that generated assets remain', (
    tester,
  ) async {
    _useMobileViewport(tester);
    const document = Document(
      id: 'document-1',
      courseId: 'course-1',
      sourceType: DocumentSourceType.pdf,
      title: 'Reaction notes',
      status: DocumentStatus.ready,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentByIdProvider.overrideWith(
            (ref, id) => Stream.value(document),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DocumentDetailScreen(documentId: 'document-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete document record?'), findsOneWidget);
    expect(
      find.textContaining('Generated decks and summaries are retained'),
      findsOneWidget,
    );
  });
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _CourseFormLauncher extends StatelessWidget {
  const _CourseFormLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCourseFormSheet(context),
            child: const Text('Open form'),
          ),
        ),
      ),
    );
  }
}
