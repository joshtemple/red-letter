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
          home: PromptedScreen(state: state, onContinue: (val) {}),
        ),
      );

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
          home: PromptedScreen(state: state, onContinue: (val) {}),
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
          home: PromptedScreen(state: state, onContinue: (val) {}),
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
    testWidgets('should validate unicode/accented words correctly', (
      tester,
    ) async {
      final uniPassage = Passage.fromText(
        id: '2',
        text: '“Agapé” means love.',
        reference: 'Ref',
      );
      final uniState = PracticeState.initial(uniPassage);

      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(state: uniState, onContinue: (val) {}),
        ),
      );

      // 1. Type "Agape" (without accent) -> Should NOT match (because strict match requires accent on content)
      // Actually, wait. My new _cleanWord logic removes PUNCTUATION/SYMBOLS.
      // But it does NOT normalize accents (e.g. é -> e).
      // So Agapé != Agape.
      // So 'Agape' should be incorrect.
      await tester.enterText(find.byType(TextField), 'Agape');
      await tester.pump();

      // Should be error
      expect(find.byKey(const Key('typed_text')), findsOneWidget);
      final textWidget = tester.widget<Text>(
        find.byKey(const Key('typed_text')),
      );
      expect(textWidget.style?.color, RedLetterColors.error);

      // Wait for clear
      await tester.pump(const Duration(milliseconds: 400));

      // 2. Type "Agapé" (with accent) -> Should match
      await tester.enterText(find.byType(TextField), 'Agapé');
      await tester.pump();

      // Should be accepted and input cleared
      expect(
        find.text('Agapé'),
        findsNothing,
      ); // Should be cleared from input (or moved effectively)
      // Wait, InlinePassageView renders the input. If it matched, it gets cleared.
      // But let's check input controller.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });
}
