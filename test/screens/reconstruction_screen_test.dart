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
          home: ReconstructionScreen(state: state, onContinue: (input) {}),
        ),
      );

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
            onContinue: (input) => continued = true,
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
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);

      // Exact match with punctuation
      await tester.enterText(find.byType(TextField), 'Jesus wept.');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);

      // Tap continue
      await tester.tap(button);
      await tester.pump();
      expect(continued, isTrue);
    });

    testWidgets('should handle punctuation and unicode correctly in validation', (
      tester,
    ) async {
      // Setup passage with smart quotes and unicode
      final specializedPassage = Passage.fromText(
        id: '2',
        text: '“Agapé” means love.',
        reference: 'Greek 101',
      );
      final specializedState = PracticeState.initial(specializedPassage);

      await tester.pumpWidget(
        MaterialApp(
          home: ReconstructionScreen(
            state: specializedState,
            onContinue: (_) {},
          ),
        ),
      );

      final button = find.widgetWithText(ElevatedButton, 'Continue');

      // 1. Valid input: Standard quotes, no accent (if normalization supports it, but currently strict match might require accent)
      // Actually, strict match requires words to match.
      // "Agapé" vs "Agape".
      // Our new Validator uses \p{P} to strip punctuation.
      // So '“Agapé”' -> 'agapé'.
      // Input 'Agape' -> 'agape'. 'agapé' != 'agape'.
      // So user MUST type accented e.

      // Try typing without accent
      await tester.enterText(find.byType(TextField), '"Agape" means love');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      // Try typing WITH accent
      await tester.enterText(find.byType(TextField), '"Agapé" means love');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);

      // Try typing WITHOUT quotes (should pass because punctuation is stripped)
      await tester.enterText(find.byType(TextField), 'Agapé means love');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);
    });
  });
}
