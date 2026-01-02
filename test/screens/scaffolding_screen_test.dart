import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';
import 'package:red_letter/theme/colors.dart';

void main() {
  group('ScaffoldingScreen', () {
    late PracticeState testState;
    late Passage testPassage;
    late WordOcclusion testOcclusion;
    late bool continuePressed;

    setUp(() {
      testPassage = Passage.fromText(
        id: 'mat-5-44',
        text: 'Love your enemies and pray for those who persecute you',
        reference: 'Matthew 5:44',
      );
      testState = PracticeState.initial(
        testPassage,
      ).copyWith(currentMode: PracticeMode.scaffolding);
      // Use seeded occlusion for deterministic testing
      testOcclusion = WordOcclusion.generate(passage: testPassage, seed: 42);
      continuePressed = false;
    });

    testWidgets('should display mode title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            onReset: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      expect(find.text(testState.currentPassage.reference), findsOneWidget);
    });

    testWidgets('should display passage with some words hidden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            onReset: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      await tester.pump();

      final richTextFinder = find.byKey(const Key('passage_text'));
      expect(richTextFinder, findsOneWidget);

      // With WidgetSpan, toPlainText has placeholders.
      // We can check for the presence of drawing containers.
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display hidden input field (autofocused)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            onReset: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Allow post-frame callback to fire

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // Verify transparency/hidden nature?
      // style color is transparent.
    });

    testWidgets('should reveal first hidden word when typed correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            onReset: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      // Identify first hidden word
      final firstHiddenIndex = testOcclusion.firstHiddenIndex;
      expect(firstHiddenIndex, isNotNull);
      final hiddenWord = testPassage.words[firstHiddenIndex!];

      // Type the hidden word
      await tester.enterText(find.byType(TextField), hiddenWord);
      await tester.pump();

      // In the new WidgetSpan implementation, revealed words become normal TextSpans.
      final richText = tester.widget<RichText>(
        find.byKey(const Key('passage_text')),
      );
      final textSpan = richText.text as TextSpan;

      // Find the span containing the revealed word and check its color
      bool foundCorrectColor = false;
      void checkSpan(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text == hiddenWord &&
              span.style?.color == RedLetterColors.correct) {
            foundCorrectColor = true;
          }
          if (span.children != null) {
            for (final child in span.children!) {
              checkSpan(child);
            }
          }
        }
      }

      checkSpan(textSpan);
      expect(foundCorrectColor, isTrue);

      // Input should be cleared on success
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should NOT reveal random hidden word (must be sequential)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            onReset: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      // Find a hidden word that is NOT the first one
      // With seed 42, passage length 10.
      // Let's iterate.
      int? secondHiddenIndex;
      final firstHiddenIndex = testOcclusion.firstHiddenIndex!;
      for (int i = firstHiddenIndex + 1; i < testPassage.words.length; i++) {
        if (testOcclusion.isWordHidden(i)) {
          secondHiddenIndex = i;
          break;
        }
      }

      // If we found a second hidden word
      if (secondHiddenIndex != null) {
        final hiddenWord = testPassage.words[secondHiddenIndex];

        // Type it. Note: under the new "Delayed Feedback" logic,
        // it only clears if input.length >= targetWord.length and prefix is wrong.
        // Or if length exceeds target.
        await tester.enterText(find.byType(TextField), hiddenWord);
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        final targetWord = testPassage.words[firstHiddenIndex];

        if (hiddenWord.length >= targetWord.length) {
          await tester.pump(const Duration(milliseconds: 400));
          expect(textField.controller?.text, isEmpty);
        } else {
          expect(textField.controller?.text, equals(hiddenWord));
        }
      }
    });

    testWidgets(
      'should enable continue button and auto-advance when all words revealed sequentially',
      (WidgetTester tester) async {
        final shortPassage = Passage.fromText(
          id: 'test',
          text: 'Love God',
          reference: 'Test 1:1',
        );
        final shortOcclusion = WordOcclusion.manual(
          passage: shortPassage,
          hiddenIndices: {0, 1},
        );
        final shortState = PracticeState.initial(
          shortPassage,
        ).copyWith(currentMode: PracticeMode.scaffolding);

        await tester.pumpWidget(
          MaterialApp(
            home: ScaffoldingScreen(
              state: shortState,
              onContinue: () => continuePressed = true,
              onReset: () {},
              occlusion: shortOcclusion,
            ),
          ),
        );

        // Type "Love"
        await tester.enterText(find.byType(TextField), 'Love');
        await tester.pump();
        expect(continuePressed, isFalse);

        // Type "God"
        await tester.enterText(find.byType(TextField), 'God');
        await tester.pump();

        // Should auto-advance
        expect(continuePressed, isTrue);
      },
    );

    testWidgets(
      'should preserve fixed length underline when typing partial word',
      (WidgetTester tester) async {
        final passage = Passage.fromText(
          id: 'test',
          text: 'Love God',
          reference: 'Test 1:1',
        );
        final occlusion = WordOcclusion.manual(
          passage: passage,
          hiddenIndices: {0},
        );
        final state = PracticeState.initial(
          passage,
        ).copyWith(currentMode: PracticeMode.scaffolding);

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

        // Type "L" (correct first char of "Love")
        await tester.enterText(find.byType(TextField), 'L');
        await tester.pump();

        // Check for the rendered 'L'
        final typedTextFinder = find.byKey(const Key('typed_text'));
        expect(typedTextFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(typedTextFinder);
        expect(textWidget.data, equals('L'));
      },
    );

    testWidgets('should handle error feedback and clearing logic', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            onReset: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      final firstHiddenIndex = testOcclusion.firstHiddenIndex!;
      final hiddenWord =
          testPassage.words[firstHiddenIndex]; // e.g. "Love" or "enemies"

      // 1. Type incorrect character -> Should NOT clear and should stay accent color
      await tester.enterText(find.byType(TextField), 'X');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        equals('X'),
      );
      final textWidget1 = tester.widget<Text>(
        find.byKey(const Key('typed_text')),
      );
      expect(textWidget1.style?.color, RedLetterColors.accent);

      // 2. Type deep error at full length -> Should turn red, then clear after delay
      String deepError = 'X' * hiddenWord.length;
      await tester.enterText(find.byType(TextField), deepError);
      await tester.pump();

      // Should show the error text in red initially
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        equals(deepError),
      );
      final errorWidget = tester.widget<Text>(
        find.byKey(const Key('typed_text')),
      );
      expect(errorWidget.style?.color, RedLetterColors.error);

      // Advance time to trigger the clear
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );

      // 3. Type correct prefix then incorrect final character -> Should keep and turn red
      final correctPrefix = hiddenWord.substring(0, hiddenWord.length - 1);
      final incorrectChar = 'Z';
      await tester.enterText(
        find.byType(TextField),
        correctPrefix + incorrectChar,
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(correctPrefix + incorrectChar));

      // Now it should be red because it's full length and incorrect
      final textWidget2 = tester.widget<Text>(
        find.byKey(const Key('typed_text')),
      );
      expect(textWidget2.style?.color, RedLetterColors.error);
      // And it should NOT clear (it's a 1-char typo)
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        equals(correctPrefix + incorrectChar),
      );

      // 4. Type past the length -> Should turn red then clear after delay
      await tester.enterText(
        find.byType(TextField),
        correctPrefix + incorrectChar + 'Y',
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        contains('Y'),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
    });
  });
}
