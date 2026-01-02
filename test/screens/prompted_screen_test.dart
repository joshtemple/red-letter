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

    testWidgets('should render reference and input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(state: state, onContinue: () {}, onReset: () {}),
        ),
      );

      expect(find.text('John 11:35'), findsOneWidget);
      expect(find.text('Type the passage from memory:'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should enable continue button when input matches', (
      tester,
    ) async {
      bool continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(
            state: state,
            onContinue: () => continued = true,
            onReset: () {},
          ),
        ),
      );

      // Initial state: continue disabled
      // Note: ElevatedButton doesn't have an 'enabled' property on the widget itself,
      // but we can check if onPressed is null.
      final button = find.widgetWithText(ElevatedButton, 'Continue');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      // Enter partial text
      await tester.enterText(find.byType(TextField), 'Jesus');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      // Enter correct text
      await tester.enterText(find.byType(TextField), 'Jesus wept');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);

      // Tap continue
      await tester.tap(button);
      await tester.pump();
      expect(continued, isTrue);
    });

    testWidgets('should show validation error for incorrect input', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(state: state, onContinue: () {}, onReset: () {}),
        ),
      );

      // Enter incorrect text
      await tester.enterText(find.byType(TextField), 'Jesus x');
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final style = textField.style;
      expect(style?.color, RedLetterColors.error);
    });

    testWidgets('should show normal text color for correct prefix', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(state: state, onContinue: () {}, onReset: () {}),
        ),
      );

      // Enter correct prefix
      await tester.enterText(find.byType(TextField), 'Jesus');
      await tester.pump();

      // Check color is NOT error
      final textField = tester.widget<TextField>(find.byType(TextField));
      final style = textField.style;
      expect(style?.color, isNot(RedLetterColors.error));
    });

    testWidgets('should show hint when requested', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PromptedScreen(state: state, onContinue: () {}, onReset: () {}),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Jesus');
      await tester.pump();

      // Tap hint icon
      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pump(); // Start animation
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // Wait for animation

      expect(find.text('Hint: wept'), findsOneWidget);
    });
  });
}
