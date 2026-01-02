import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';
import 'package:red_letter/widgets/passage_text.dart';

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

      // Should find some underscores (hidden words)
      final textFinders = find.byType(Text);
      final texts = tester.widgetList<Text>(textFinders);
      final hasUnderscores = texts.any((text) {
        final data = text.data;
        return data != null && data.contains('_');
      });
      expect(hasUnderscores, true);
    });

    testWidgets('should display passage reference', (
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

      expect(find.text(testState.currentPassage.reference), findsOneWidget);
    });

    testWidgets('should display input field with hint', (
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

      expect(find.byType(PassageInput), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Type the missing words...');
    });

    testWidgets('should display continue button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: testState,
            onContinue: () {},
            occlusion: testOcclusion,
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('continue button should be disabled initially', (
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

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should reveal word and clear input when typed correctly', (
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

      // Get a word that we know is hidden from the seeded occlusion
      int? hiddenIndex;
      for (int i = 0; i < testPassage.words.length; i++) {
        if (testOcclusion.isWordHidden(i)) {
          hiddenIndex = i;
          break;
        }
      }

      expect(hiddenIndex, isNotNull);
      final hiddenWord = testPassage.words[hiddenIndex!];

      // Verify word is initially not displayed in passage (body text contains underscores)
      // Note: This relies on how Text widgets are constructed.
      // Easiest is to verify hiddenWord is NOT found.
      // But verify it is not found as a standalone word?
      // The passage is one big string. "Love your _______"
      // So 'enemies' should not be found.
      // But we have 'enemies' in testPassage.text which might be in memory.
      // find.text searchs for Widgets.

      // Type the hidden word
      await tester.enterText(find.byType(TextField), hiddenWord);
      await tester.pump();

      // Input should be cleared
      expect(
        find.textContaining(hiddenWord),
        findsOneWidget,
      ); // Found in passage now
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should be case insensitive for word matching', (
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

      // Get a hidden word
      int? hiddenIndex;
      for (int i = 0; i < testPassage.words.length; i++) {
        if (testOcclusion.isWordHidden(i)) {
          hiddenIndex = i;
          break;
        }
      }

      final hiddenWord = testPassage.words[hiddenIndex!];
      final upperCaseWord = hiddenWord.toUpperCase();

      // Type in different case
      await tester.enterText(find.byType(TextField), upperCaseWord);
      await tester.pump();

      // Should still reveal the word (found in passage text)
      // The passage text will display the original case from the passage model
      expect(find.textContaining(hiddenWord), findsOneWidget);
    });

    testWidgets('should enable continue button when all words revealed', (
      WidgetTester tester,
    ) async {
      final shortPassage = Passage.fromText(
        id: 'test',
        text: 'Love God',
        reference: 'Test 1:1',
      );
      final shortOcclusion = WordOcclusion.generate(
        passage: shortPassage,
        seed: 42,
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

      await tester.pump();

      // Type all words
      // Since we clear input on match, we need to type them one by one if they are separate checks
      // But checkInput handles multiple tokens.
      // However, checkInput clears buffer on match.
      // If we type "Love God".
      // "Love" matches -> clear. " God" is lost?
      // Wait, if I type "Love God" via tester.enterText, it sets the whole text at once.
      // _handleInputChange("Love God") ->
      // checkInput("Love God") -> matches "Love" and "God".
      // Returns new occlusion with both revealed.
      // Clears input.
      // So it should work.
      await tester.enterText(find.byType(TextField), shortPassage.text);
      await tester.pump();

      // Button should be enabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should call onContinue when button pressed after completion', (
      WidgetTester tester,
    ) async {
      final shortPassage = Passage.fromText(
        id: 'test',
        text: 'Love God',
        reference: 'Test 1:1',
      );
      final shortOcclusion = WordOcclusion.generate(
        passage: shortPassage,
        seed: 42,
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

      await tester.pump();

      expect(continuePressed, false);

      // Type all words to enable button
      await tester.enterText(find.byType(TextField), shortPassage.text);
      await tester.pump();

      // Tap continue button
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continuePressed, true);
    });

    testWidgets('should be scrollable for long passages', (
      WidgetTester tester,
    ) async {
      final longPassage = Passage.fromText(
        id: 'long',
        text: 'This is a very long passage ' * 50,
        reference: 'Test 1:1',
      );
      final longOcclusion = WordOcclusion.generate(
        passage: longPassage,
        seed: 42,
      );
      final longState = PracticeState.initial(
        longPassage,
      ).copyWith(currentMode: PracticeMode.scaffolding);

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldingScreen(
            state: longState,
            onContinue: () {},
            occlusion: longOcclusion,
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (
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

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });
  });
}
