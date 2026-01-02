import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
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
        text: 'Love your enemies and pray for those who persecute you',
        reference: 'Matthew 5:44',
      );
      testState = PracticeState.initial(passage);
      continuePressed = false;
    });

    testWidgets('should display mode title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.text('Impression'), findsOneWidget);
    });

    testWidgets('should display passage text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.text(testState.currentPassage.text), findsOneWidget);
      expect(find.text(testState.currentPassage.reference), findsOneWidget);
    });

    testWidgets('should display PassageText widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.byType(PassageText), findsOneWidget);
      final passageText = tester.widget<PassageText>(find.byType(PassageText));
      expect(passageText.passage, testState.currentPassage);
      expect(passageText.textAlign, TextAlign.center);
      expect(passageText.showReference, true);
      expect(passageText.enableShadow, true);
    });

    testWidgets('should display mnemonic placeholder',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('should display continue button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onContinue when button pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () => continuePressed = true,
          ),
        ),
      );

      expect(continuePressed, false);

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
      final longState = PracticeState.initial(longPassage);

      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: longState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper layout structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: testState,
            onContinue: () {},
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('should work with different passages',
        (WidgetTester tester) async {
      final passage2 = Passage.fromText(
        id: 'john-3-16',
        text: 'For God so loved the world',
        reference: 'John 3:16',
      );
      final state2 = PracticeState.initial(passage2);

      await tester.pumpWidget(
        MaterialApp(
          home: ImpressionScreen(
            state: state2,
            onContinue: () {},
          ),
        ),
      );

      expect(find.text('For God so loved the world'), findsOneWidget);
      expect(find.text('John 3:16'), findsOneWidget);
    });
  });
}
