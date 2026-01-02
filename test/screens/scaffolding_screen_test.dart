import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';

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
            occlusion: testOcclusion,
          ),
        ),
      );

      expect(find.text('Scaffolding'), findsOneWidget);
    });

    testWidgets('should display passage with some words hidden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      await tester.pump();

      final richTextFinder = find.byKey(const Key('passage_text'));
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      final plainText = richText.text.toPlainText();

      expect(plainText.contains('_'), isTrue);
    });

    testWidgets('should display hidden input field (autofocused)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.autofocus, isTrue);

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

      // Check RichText for revealed word
      final richText = tester.widget<RichText>(
        find.byKey(const Key('passage_text')),
      );
      final plainText = richText.text.toPlainText();

      // It should contain the word now (revealed)
      expect(plainText.contains(hiddenWord), isTrue);
      // And should NOT contain underscores at that position (hard to verifying position with plainText)
      // But we can check hiddenIndices count via state? No access to private state.
      // We rely on appearance.

      // Input should be cleared
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

        // Type it
        await tester.enterText(find.byType(TextField), hiddenWord);
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        // Input NOT cleared
        expect(textField.controller?.text, equals(hiddenWord));
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
              occlusion: shortOcclusion,
            ),
          ),
        );

        // Type "Love"
        await tester.enterText(find.byType(TextField), 'Love');
        await tester.pumpAndSettle();
        expect(continuePressed, isFalse);

        // Type "God"
        await tester.enterText(find.byType(TextField), 'God');
        await tester.pumpAndSettle();

        // Should auto-advance
        expect(continuePressed, isTrue);
      },
    );

    testWidgets(
      'should preserve fixed length underline when typing partial word',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ScaffoldingScreen(
              state: testState,
              onContinue: () {},
              occlusion: testOcclusion,
            ),
          ),
        );

        // Get initial text length
        final richTextBefore = tester.widget<RichText>(
          find.byKey(const Key('passage_text')),
        );
        final lengthBefore = richTextBefore.text.toPlainText().length;

        // Type "X"
        await tester.enterText(find.byType(TextField), 'X');
        await tester.pump();

        // Check RichText content
        final richTextAfter = tester.widget<RichText>(
          find.byKey(const Key('passage_text')),
        );
        final plainTextAfter = richTextAfter.text.toPlainText();

        expect(plainTextAfter.contains('X'), isTrue);
        // Length should remain mostly constant (padded)
        // Note: punctuation or multiple spaces might shift it, but for simple strings it's static.
        expect(plainTextAfter.length, equals(lengthBefore));
      },
    );
  });
}
