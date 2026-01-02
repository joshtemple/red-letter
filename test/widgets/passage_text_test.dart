import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';

void main() {
  group('PassageText', () {
    late Passage testPassage;

    setUp(() {
      testPassage = Passage.fromText(
        id: 'mat-5-44',
        text: 'Love your enemies and pray for those who persecute you',
        reference: 'Matthew 5:44',
      );
    });

    testWidgets('should display passage text with reference',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageText(passage: testPassage),
          ),
        ),
      );

      expect(find.text(testPassage.reference), findsOneWidget);
      expect(find.text(testPassage.text), findsOneWidget);
    });

    testWidgets('should hide reference when showReference is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageText(
              passage: testPassage,
              showReference: false,
            ),
          ),
        ),
      );

      expect(find.text(testPassage.reference), findsNothing);
      expect(find.text(testPassage.text), findsOneWidget);
    });

    testWidgets('should use RepaintBoundary for performance',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageText(passage: testPassage),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('should apply correct text styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageText(passage: testPassage),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final referenceText = textWidgets.first;
      final bodyText = textWidgets.last;

      expect(referenceText.style, RedLetterTypography.passageReference);
      expect(bodyText.style, RedLetterTypography.passageBody);
    });

    testWidgets('should apply shadow when enableShadow is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageText(
              passage: testPassage,
              enableShadow: true,
            ),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final bodyText = textWidgets.last;

      expect(bodyText.style?.shadows, isNotEmpty);
    });
  });

  group('PassageInput', () {
    testWidgets('should create input field with correct style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PassageInput(),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style, RedLetterTypography.userInputText);
    });

    testWidgets('should use monospace when specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PassageInput(useMonospace: true),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style, RedLetterTypography.userInputTextMonospace);
    });

    testWidgets('should call onChanged when text changes',
        (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageInput(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Love your enemies');
      expect(changedValue, 'Love your enemies');
    });

    testWidgets('should display hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PassageInput(
              hintText: 'Type here...',
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Type here...');
    });

    testWidgets('should use RepaintBoundary for performance',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PassageInput(),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('should disable autocorrect and suggestions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PassageInput(),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autocorrect, false);
      expect(textField.enableSuggestions, false);
    });
  });
}
