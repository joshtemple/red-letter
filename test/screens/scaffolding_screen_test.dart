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
      testState = PracticeState.initial(testPassage).copyWith(
        currentMode: PracticeMode.scaffolding,
      );
      // Use seeded occlusion for deterministic testing
      testOcclusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );
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

    testWidgets('should display progress indicator',
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

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('words revealed'), findsOneWidget);
    });

    testWidgets('should display passage with some words hidden',
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

    testWidgets('should display passage reference',
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

      expect(find.text(testState.currentPassage.reference), findsOneWidget);
    });

    testWidgets('should display input field with hint',
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

      expect(find.byType(PassageInput), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Type the missing words...');
    });

    testWidgets('should display continue button',
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

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('continue button should be disabled initially',
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

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should reveal word when typed correctly',
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

      // Type the hidden word
      await tester.enterText(find.byType(TextField), hiddenWord);
      await tester.pump();

      // Progress should increase
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('should reveal multiple words when typed',
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

      // Get all hidden words
      final hiddenWords = <String>[];
      for (int i = 0; i < testPassage.words.length; i++) {
        if (testOcclusion.isWordHidden(i)) {
          hiddenWords.add(testPassage.words[i]);
        }
      }

      // Type multiple hidden words
      await tester.enterText(
        find.byType(TextField),
        hiddenWords.take(2).join(' '),
      );
      await tester.pump();

      // Progress should show multiple words revealed
      expect(find.textContaining('2 /'), findsOneWidget);
    });

    testWidgets('should be case insensitive for word matching',
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

      // Get a hidden word
      int? hiddenIndex;
      for (int i = 0; i < testPassage.words.length; i++) {
        if (testOcclusion.isWordHidden(i)) {
          hiddenIndex = i;
          break;
        }
      }

      final hiddenWord = testPassage.words[hiddenIndex!].toUpperCase();

      // Type in different case
      await tester.enterText(find.byType(TextField), hiddenWord);
      await tester.pump();

      // Should still reveal the word
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('should update progress as words are revealed',
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

      // Initially 0 revealed
      expect(find.textContaining('0 /'), findsOneWidget);

      // Get a hidden word
      int? hiddenIndex;
      for (int i = 0; i < testPassage.words.length; i++) {
        if (testOcclusion.isWordHidden(i)) {
          hiddenIndex = i;
          break;
        }
      }

      final hiddenWord = testPassage.words[hiddenIndex!];

      // Type a word
      await tester.enterText(find.byType(TextField), hiddenWord);
      await tester.pump();

      // Progress updated
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('should enable continue button when all words revealed',
        (WidgetTester tester) async {
      final shortPassage = Passage.fromText(
        id: 'test',
        text: 'Love God',
        reference: 'Test 1:1',
      );
      final shortOcclusion = WordOcclusion.generate(
        passage: shortPassage,
        seed: 42,
      );
      final shortState = PracticeState.initial(shortPassage).copyWith(
        currentMode: PracticeMode.scaffolding,
      );

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
      await tester.enterText(find.byType(TextField), shortPassage.text);
      await tester.pump();

      // Button should be enabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should call onContinue when button pressed after completion',
        (WidgetTester tester) async {
      final shortPassage = Passage.fromText(
        id: 'test',
        text: 'Love God',
        reference: 'Test 1:1',
      );
      final shortOcclusion = WordOcclusion.generate(
        passage: shortPassage,
        seed: 42,
      );
      final shortState = PracticeState.initial(shortPassage).copyWith(
        currentMode: PracticeMode.scaffolding,
      );

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

    testWidgets('should be scrollable for long passages',
        (WidgetTester tester) async {
      final longPassage = Passage.fromText(
        id: 'long',
        text: 'This is a very long passage ' * 50,
        reference: 'Test 1:1',
      );
      final longOcclusion = WordOcclusion.generate(
        passage: longPassage,
        seed: 42,
      );
      final longState = PracticeState.initial(longPassage).copyWith(
        currentMode: PracticeMode.scaffolding,
      );

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

    testWidgets('should have proper layout structure',
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

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('should not reveal words that are not hidden',
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

      await tester.pump();

      // Type all words from passage
      await tester.enterText(
        find.byType(TextField),
        testState.currentPassage.text,
      );
      await tester.pump();

      // Progress should only count hidden words that were revealed
      final progressText = tester
          .widgetList<Text>(find.textContaining('words revealed'))
          .first
          .data!;

      // Extract the revealed and total counts
      final match = RegExp(r'(\d+) / (\d+)').firstMatch(progressText);
      expect(match, isNotNull);
      final revealed = int.parse(match!.group(1)!);
      final total = int.parse(match.group(2)!);

      // Revealed should equal total (all hidden words revealed)
      expect(revealed, total);

      // Total should be less than the full word count (only hidden words)
      expect(total, lessThan(testState.currentPassage.words.length));
    });
  });
}
