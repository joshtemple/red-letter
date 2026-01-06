import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/impression_screen.dart';
import 'package:red_letter/widgets/passage_text.dart';

void main() {
  group('ImpressionScreen', () {
    late PracticeState testState;
    late bool continuePressed;

    setUp(() {
      final passage = Passage.fromText(
        id: 'mat-5-44',
        text: 'Love your enemies, and pray for those who persecute you.',
        reference: 'Matthew 5:44',
      );
      testState = PracticeState.initial(passage);
      continuePressed = false;
    });

    testWidgets('should display tap-to-reveal instruction initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback

      expect(find.text('Tap to reveal the passage'), findsOneWidget);
      expect(find.text('Read this passage aloud twice'), findsNothing);
    });

    testWidgets('should initially reveal only first clause', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback
      await tester.pump(const Duration(milliseconds: 300)); // Complete animation

      // First clause should be visible
      expect(find.textContaining('Love your enemies', findRichText: true), findsOneWidget);
      // Second clause should not be visible yet
      expect(find.textContaining('pray for those', findRichText: true), findsNothing);
    });

    testWidgets('should reveal next clause on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback
      await tester.pump(const Duration(milliseconds: 300)); // Complete first animation

      // Tap to reveal second clause
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Complete animation

      // Both clauses should now be visible
      expect(find.textContaining('Love your enemies', findRichText: true), findsOneWidget);
      expect(find.textContaining('pray for those', findRichText: true), findsOneWidget);
    });

    testWidgets('should not show footer until all clauses revealed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback

      // Footer should not be visible initially
      expect(find.text('Continue'), findsNothing);

      // Tap to reveal second (final) clause
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Complete animation

      // Footer should now be visible
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('should update instruction text when fully revealed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback

      expect(find.text('Tap to reveal the passage'), findsOneWidget);

      // Tap to reveal all clauses
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Instruction should change
      expect(find.text('Tap to reveal the passage'), findsNothing);
      expect(find.text('Read this passage aloud twice'), findsOneWidget);
    });

    testWidgets('should call onContinue when button pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () => continuePressed = true,
          ),
        ),
      );
      await tester.pump(); // Process post-frame callback

      // Reveal all clauses
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(continuePressed, false);

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continuePressed, true);
    });

    testWidgets('should display RevealablePassageText widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump();

      expect(find.byType(RevealablePassageText), findsOneWidget);
      final passageText = tester.widget<RevealablePassageText>(
        find.byType(RevealablePassageText),
      );
      expect(passageText.passage, testState.currentPassage);
      expect(passageText.textAlign, TextAlign.start);
      expect(passageText.enableShadow, true);
    });

    testWidgets('should handle single-clause passage', (
      WidgetTester tester,
    ) async {
      final singleClausePassage = Passage.fromText(
        id: 'short',
        text: 'Rejoice.',
        reference: 'Test 1:1',
      );
      final singleClauseState = PracticeState.initial(singleClausePassage);

      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: singleClauseState, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback
      await tester.pump(const Duration(milliseconds: 300)); // Complete animation

      // Single clause should be visible
      expect(find.textContaining('Rejoice', findRichText: true), findsOneWidget);

      // Footer should be visible (all clauses revealed)
      expect(find.text('Continue'), findsOneWidget);

      // Instruction should show read-aloud text
      expect(find.text('Read this passage aloud twice'), findsOneWidget);
    });

    testWidgets('should ignore taps after all clauses revealed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump();

      // Reveal all clauses
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Continue'), findsOneWidget);

      // Tap again - should not cause any issues
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      // Continue button should still be there
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('should be scrollable for long passages', (
      WidgetTester tester,
    ) async {
      final longPassage = Passage.fromText(
        id: 'long',
        text: 'This is a very long passage, ' * 50,
        reference: 'Test 1:1',
      );
      final longState = PracticeState.initial(longPassage);

      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: longState, onContinue: () {}),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('should work with different passages', (
      WidgetTester tester,
    ) async {
      final passage2 = Passage.fromText(
        id: 'john-3-16',
        text: 'For God so loved the world, that he gave his only Son.',
        reference: 'John 3:16',
      );
      final state2 = PracticeState.initial(passage2);

      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: state2, onContinue: () {}),
        ),
      );
      await tester.pump(); // Process post-frame callback
      await tester.pump(const Duration(milliseconds: 300)); // Complete animation

      expect(find.textContaining('For God so loved the world', findRichText: true), findsOneWidget);
    });

    testWidgets('should animate newly revealed clause', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(state: testState, onContinue: () {}),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap to reveal second clause
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(); // Start animation (opacity at 0)

      // Animation should be running - second clause fading in
      await tester.pump(const Duration(milliseconds: 150)); // Mid-animation

      // Complete animation
      await tester.pump(const Duration(milliseconds: 150));

      // Both clauses fully visible
      expect(find.textContaining('Love your enemies', findRichText: true), findsOneWidget);
      expect(find.textContaining('pray for those', findRichText: true), findsOneWidget);
    });
  });
}
