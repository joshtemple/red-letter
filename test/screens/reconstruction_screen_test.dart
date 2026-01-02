import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/reconstruction_screen.dart';

void main() {
  group('ReconstructionScreen', () {
    late Passage passage;
    late PracticeState state;

    setUp(() {
      passage = Passage.fromText(
        id: '1',
        text: 'Jesus wept.',
        reference: 'John 11:35',
      );
      state = PracticeState.initial(passage);
    });

    testWidgets('should render reference and input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReconstructionScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
          ),
        ),
      );

      expect(find.text('John 11:35'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type the passage...'), findsOneWidget);
    });

    testWidgets('should enable continue button when input matches strictly', (
      tester,
    ) async {
      bool continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ReconstructionScreen(
            state: state,
            onContinue: () => continued = true,
            onReset: () {},
          ),
        ),
      );

      final button = find.widgetWithText(ElevatedButton, 'Continue');
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      // Partial
      await tester.enterText(find.byType(TextField), 'Jesus');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      // Missing punctuation (Strict Match requires it)
      await tester.enterText(find.byType(TextField), 'Jesus wept');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      // Exact match with punctuation
      await tester.enterText(find.byType(TextField), 'Jesus wept.');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);

      // Tap continue
      await tester.tap(button);
      await tester.pump();
      expect(continued, isTrue);
    });
  });
}
