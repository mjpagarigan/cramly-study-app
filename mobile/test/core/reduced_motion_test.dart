import 'package:cramly/core/theme/app_theme.dart';
import 'package:cramly/shared/widgets/learning_trace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LearningTrace renders its final state with reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LearningTrace()),
        ),
      ),
    );
    await tester.pump();

    final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
    expect(opacityWidgets, isNotEmpty);
    expect(opacityWidgets.every((widget) => widget.opacity == 1), isTrue);
  });
}
