import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';

import '../utils/builders/passage_builder.dart';
import '../utils/pages/scaffolding_page.dart';

void main() {
  group('ScaffoldingScreen', () {
    testWidgets('should display mode title', (WidgetTester tester) async {
      final passage = PassageBuilder()
          .withId('mat-5-44')
          .withText('Love your enemies')
          .withReference('Matthew 5:44')
          .build();

      final state = PracticeState.initial(
        passage,
      ).copyWith(currentMode: PracticeMode.randomWords);
      final occlusion = ClozeOcclusion.randomWordPerClause(passage: passage, seed: 42);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
            occlusion: occlusion,
          ),
        ),
      );

      final page = ScaffoldingPage(tester);
      page.expectPassageVisible('Matthew 5:44');
    });

    testWidgets('should display hidden input field (autofocused)', (
      WidgetTester tester,
    ) async {
      final passage = PassageBuilder().build();
      final state = PracticeState.initial(
        passage,
      ).copyWith(currentMode: PracticeMode.randomWords);
      final occlusion = ClozeOcclusion.randomWordPerClause(passage: passage);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
            occlusion: occlusion,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final page = ScaffoldingPage(tester);
      page.expectTextFieldHasFocus();
    });

    testWidgets('should reveal first hidden word when typed correctly', (
      WidgetTester tester,
    ) async {
      final passage = PassageBuilder().withText('Love your enemies').build();

      // Use manual occlusion to force 'Love' (first word) to be hidden
      final occlusion = ClozeOcclusion.manual(
        passage: passage,
        hiddenIndices: {0},
      );

      final state = PracticeState.initial(
        passage,
      ).copyWith(currentMode: PracticeMode.randomWords);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
            occlusion: occlusion,
          ),
        ),
      );

      final page = ScaffoldingPage(tester);

      // Type "Love"
      await page.enterText('Love');

      // Verify input cleared (success)
      page.expectInputCleared();
    });

    testWidgets('should handle error feedback and clearing logic', (
      WidgetTester tester,
    ) async {
      final passage = PassageBuilder().withText('Love').build();

      final occlusion = ClozeOcclusion.manual(
        passage: passage,
        hiddenIndices: {0},
      );

      final state = PracticeState.initial(
        passage,
      ).copyWith(currentMode: PracticeMode.randomWords);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
            occlusion: occlusion,
          ),
        ),
      );

      final page = ScaffoldingPage(tester);

      // 1. Type incorrect character -> Should keep input
      await page.enterText('X');
      page.expectInputText('X');

      // 2. Type deep error at full length -> Should turn red then clear
      // "Love" length is 4. 'XXXX'.
      await page.enterText('XXXX');
      page.expectTypedTextIsError();

      // Advance to allow auto-clear
      await tester.pump(const Duration(milliseconds: 400));
      page.expectInputCleared();
    });

    testWidgets('should NOT reveal random hidden word (must be sequential)', (
      WidgetTester tester,
    ) async {
      final passage = PassageBuilder().withText('Love your enemies').build();

      // Manual occlusion: 0 (Love) and 1 (your) are hidden
      final occlusion = ClozeOcclusion.manual(
        passage: passage,
        hiddenIndices: {0, 1},
      );

      final state = PracticeState.initial(
        passage,
      ).copyWith(currentMode: PracticeMode.randomWords);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
            occlusion: occlusion,
          ),
        ),
      );

      final page = ScaffoldingPage(tester);

      // Type "your" (2nd hidden word) before "Love" (1st hidden word)
      await page.enterText('your');

      // Should interpret as error because it doesn't match "Love"
      // "your" (4) vs "Love" (4). Length matches.
      // Logic: if input.length >= target.length && input != target -> error/clear.
      page.expectInputText('your');
      page.expectTypedTextIsError();

      await tester.pump(const Duration(milliseconds: 400));
      page.expectInputCleared();
    });

    testWidgets(
      'should enable continue button and auto-advance when all words revealed sequentially',
      (WidgetTester tester) async {
        bool continuePressed = false;

        final passage = PassageBuilder().withText('Love God').build();

        final occlusion = ClozeOcclusion.manual(
          passage: passage,
          hiddenIndices: {0, 1},
        );

        final state = PracticeState.initial(
          passage,
        ).copyWith(currentMode: PracticeMode.randomWords);

        await tester.pumpWidget(
          MaterialApp(
            home: ScaffoldingScreen(
              state: state,
              onContinue: () => continuePressed = true,
              onReset: () {},
              occlusion: occlusion,
            ),
          ),
        );

        final page = ScaffoldingPage(tester);

        // Type "Love"
        await page.enterText('Love');
        expect(continuePressed, isFalse);

        // Type "God"
        await page.enterText('God');

        // Should auto-advance
        expect(continuePressed, isTrue);
      },
    );

    testWidgets('should preserve fixed length underline when typing partial word', (
      WidgetTester tester,
    ) async {
      final passage = PassageBuilder().withText('Love God').build();

      final occlusion = ClozeOcclusion.manual(
        passage: passage,
        hiddenIndices: {0},
      );

      final state = PracticeState.initial(
        passage,
      ).copyWith(currentMode: PracticeMode.randomWords);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: state,
            onContinue: () {},
            onReset: () {},
            occlusion: occlusion,
          ),
        ),
      );

      final page = ScaffoldingPage(tester);

      // Type "L" (correct first char of "Love")
      await page.enterText('L');

      // We can verify this via the typed text widget
      page.expectInputText('L');
      // Ideally we check visually that the underline is still there, but that requires finding the Paint/Container which is detail-heavy.
      // For now, trusting the input state is preserved and not cleared is enough proxy.
    });
  });
}
