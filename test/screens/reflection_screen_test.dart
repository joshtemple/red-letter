import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/reflection_screen.dart';
import 'package:red_letter/widgets/passage_text.dart';

void main() {
  group('ReflectionScreen', () {
    late PracticeState testState;
    late String? submittedReflection;

    setUp(() {
      final passage = Passage.fromText(
        id: 'mat-5-44',
        text: 'Love your enemies',
        reference: 'Matthew 5:44',
      );
      testState = PracticeState.initial(passage);
      submittedReflection = null;
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReflectionScreen(
            state: testState,
            onContinue: (reflection) => submittedReflection = reflection,
          ),
        ),
      );
    }

    testWidgets('should display title and prompt', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Reflection'), findsOneWidget);
      expect(find.text('What does this command mean to you?'), findsOneWidget);
    });

    testWidgets('should display passage', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(PassageText), findsOneWidget);
      expect(find.text('Love your enemies'), findsOneWidget);
    });

    testWidgets('should focus input automatically', (tester) async {
      await pumpScreen(tester);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('should validate input before enabling continue', (
      tester,
    ) async {
      await pumpScreen(tester);

      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');

      // Initially disabled
      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);

      // Enter text (any length allowed now)
      await tester.enterText(find.byType(TextField), 'Short');
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(continueButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('should return reflection text on continue', (tester) async {
      await pumpScreen(tester);

      const validReflection =
          'This reflection is definitely long enough to be valid.';
      await tester.enterText(find.byType(TextField), validReflection);
      await tester.pump();

      await tester.tap(find.text('Continue'));
      expect(submittedReflection, validReflection);
    });
  });
}
