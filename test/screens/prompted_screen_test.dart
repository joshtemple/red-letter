import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/prompted_screen.dart';

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
          home: PromptedScreen(state: state, onContinue: () {}),
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
          ),
        ),
      );

      // Initial state: continue disabled
      final button = find.widgetWithText(ElevatedButton, 'Continue');
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      // Enter partial text
      await tester.enterText(find.byType(TextField), 'Jesus');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      // Enter correct text
      await tester.enterText(find.byType(TextField), 'Jesus wept');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);

      // Tap continue
      await tester.tap(button);
      await tester.pump();
      expect(continued, isTrue);
    });
  });
}
