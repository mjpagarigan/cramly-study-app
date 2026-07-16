import 'package:cramly/features/decks/data/deck_model.dart';
import 'package:cramly/core/theme/app_colors.dart';
import 'package:cramly/features/decks/providers/deck_providers.dart';
import 'package:cramly/features/decks/screens/deck_review_screen.dart';
import 'package:cramly/features/documents/data/document_model.dart';
import 'package:cramly/features/documents/providers/upload_state.dart';
import 'package:cramly/features/documents/widgets/file_picker_helpers.dart';
import 'package:cramly/features/documents/widgets/url_input_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Upload validation', () {
    test('maps extensions to explicit backend-compatible MIME types', () {
      expect(sourceTypeForExt('PDF')?.mimeType, 'application/pdf');
      expect(sourceTypeForExt('jpg')?.mimeType, 'image/jpeg');
      expect(sourceTypeForExt('m4a')?.mimeType, 'audio/mp4');
      expect(sourceTypeForExt('mp3')?.mimeType, 'audio/mpeg');
      expect(sourceTypeForExt('exe'), isNull);
    });

    test('enforces the general and audio size boundaries', () {
      expect(
        validateUploadSize(
          maxUploadBytes - 1,
          sourceType: DocumentSourceType.pdf,
        ),
        isNull,
      );
      expect(
        validateUploadSize(maxUploadBytes, sourceType: DocumentSourceType.pdf),
        contains('smaller than 50 MiB'),
      );
      expect(
        validateUploadSize(
          maxAudioUploadBytes,
          sourceType: DocumentSourceType.audio,
        ),
        isNull,
      );
      expect(
        validateUploadSize(
          maxAudioUploadBytes + 1,
          sourceType: DocumentSourceType.audio,
        ),
        contains('25 MiB or smaller'),
      );
    });

    test('accepts supported YouTube shapes and complete web URLs', () {
      for (final value in [
        'dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'https://youtube.com/embed/dQw4w9WgXcQ',
      ]) {
        expect(
          validateSourceUrl(value, DocumentSourceType.youtube),
          isNull,
          reason: value,
        );
      }
      expect(
        validateSourceUrl(
          'https://example.com/article',
          DocumentSourceType.webUrl,
        ),
        isNull,
      );
      expect(
        validateSourceUrl('https://www.fda.gov', DocumentSourceType.webUrl),
        isNull,
      );
      expect(
        validateSourceUrl('javascript:alert(1)', DocumentSourceType.webUrl),
        isNotNull,
      );
      expect(
        validateSourceUrl('http://localhost:3000', DocumentSourceType.webUrl),
        isNotNull,
      );
      expect(
        validateSourceUrl('http://[::]/notes', DocumentSourceType.webUrl),
        isNotNull,
      );
      expect(
        validateSourceUrl(
          'http://[::ffff:127.0.0.1]/notes',
          DocumentSourceType.webUrl,
        ),
        isNotNull,
      );
      expect(
        validateSourceUrl(
          'https://youtu.be/dQw4w9WgXcQ/extra',
          DocumentSourceType.youtube,
        ),
        isNotNull,
      );
      expect(
        validateSourceUrl(
          'https://example.com/youtube',
          DocumentSourceType.youtube,
        ),
        isNotNull,
      );
    });
  });

  test(
    'upload state retains course and uploaded path for registration retry',
    () {
      final controller = UploadController();
      controller.selectCourse('course-1');
      controller.pickedSource(
        const UploadSource.url(
          url: 'https://example.com/article',
          sourceType: DocumentSourceType.webUrl,
        ),
      );
      controller.goToAssign();
      controller.clearSource();

      expect(controller.state.step, UploadStep.source);
      expect(controller.state.courseId, 'course-1');
      expect(controller.state.source, isNull);

      controller.pickedSource(
        const UploadSource.url(
          url: 'https://example.com/article',
          sourceType: DocumentSourceType.webUrl,
        ),
      );
      controller.goToAssign();
      controller.goToProcessing();
      controller.markStorageUploaded(
        'users/u/documents/generated/original.pdf',
      );
      controller.fail('registration failed');
      controller.retryProcessing();

      expect(controller.state.errorMessage, isNull);
      expect(
        controller.state.uploadedStoragePath,
        'users/u/documents/generated/original.pdf',
      );
      expect(controller.state.uploadFraction, 1);
    },
  );

  testWidgets('review reveals hint, answer, explanation, and completion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const deck = Deck(
      id: 'deck-1',
      courseId: 'course-1',
      title: 'Biology essentials',
      description: '',
      cardCount: 2,
      generationMethod: DeckGenerationMethod.manual,
      status: DeckStatus.ready,
    );
    const cards = [
      DeckCardItem(
        id: 'card-1',
        front: 'What powers the cell?',
        back: 'ATP',
        hint: 'Three letters',
        explanation: 'ATP carries usable chemical energy.',
        topic: 'Cells',
      ),
      DeckCardItem(
        id: 'card-2',
        front: 'Where is ATP produced?',
        back: 'Mitochondria',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckByIdProvider.overrideWith((ref, id) => Stream.value(deck)),
          deckCardsProvider.overrideWith((ref, id) => Stream.value(cards)),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [AppColors.light]),
          home: const DeckReviewScreen(deckId: 'deck-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What powers the cell?'), findsOneWidget);
    expect(find.text('Three letters'), findsNothing);

    await tester.tap(find.text('Show hint'));
    await tester.pump();
    expect(find.text('Three letters'), findsOneWidget);

    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('ATP'), findsOneWidget);
    expect(find.text('ATP carries usable chemical energy.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Where is ATP produced?'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Review complete'), findsOneWidget);
    expect(find.textContaining('No ratings or study history'), findsOneWidget);
  });
}
