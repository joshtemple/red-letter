import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/prompted_screen.dart';
import 'package:red_letter/theme/colors.dart';

void main() {
  group('PromptedScreen', () {
    late Passage passage;
    late PracticeState state;

    setUp(() {
      passage = Passage.fromText(
        id: '1',
        text: 'Jesus wept',
        reference: 'John 11:35',
      );
      state = PracticeState.initial(passage);
    });

    testWidgets('should render reference and passage view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(
            state: state,
            onContinue: (val) {},
            onReset: () {},
          ),
        ),
      );

      expect(find.text('John 11:35'), findsOneWidget);
      expect(find.byKey(const Key('passage_text')), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should auto-advance when passage is typed correctly', (
      tester,
    ) async {
      bool continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(
            state: state,
            onContinue: (val) => continued = true,
            onReset: () {},
          ),
        ),
      );

      // Type "Jesus"
      await tester.enterText(find.byType(TextField), 'Jesus');
      await tester.pump();
      expect(continued, isFalse);

      // Type "wept"
      await tester.enterText(find.byType(TextField), 'wept');
      await tester.pump();

      // Should auto-advance
      expect(continued, isTrue);
    });

    testWidgets('should show error state for incorrect input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(
            state: state,
            onContinue: (val) {},
            onReset: () {},
          ),
        ),
      );

      // Enter incorrect text (full word length to trigger check)
      await tester.enterText(find.byType(TextField), 'Wrong');
      await tester.pump();

      // Should show error color (this might be hard to test directly on the InlinePassageView,
      // but we can check the text color of the typed text)
      expect(find.byKey(const Key('typed_text')), findsOneWidget);
      final textWidget = tester.widget<Text>(
        find.byKey(const Key('typed_text')),
      );
      expect(textWidget.style?.color, RedLetterColors.error);

      // Clean up timer
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('should show hint inline when requested', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(
            state: state,
            onContinue: (val) {},
            onReset: () {},
          ),
        ),
      );

      // Initially hint should not be there
      expect(find.byKey(const Key('hint_text')), findsNothing);

      // Tap hint icon (represented by the lightbulb in PracticeFooter)
      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 500)); // Wait for fade

      // Now "Jesus" (the first word) should be visible as a hint
      expect(find.byKey(const Key('hint_text')), findsOneWidget);

      final hintText = tester.widget<Text>(find.byKey(const Key('hint_text')));
      expect(
        hintText.style?.color?.opacity,
        lessThan(1.0),
      ); // Lighter contrast (0.3 in impl)
    });
  });
}
