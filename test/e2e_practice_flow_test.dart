import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/main.dart'; // Imports main app widget

void main() {
  group('End-to-End Practice Flow', () {
    testWidgets('Complete walkthrough of all practice modes', (tester) async {
      // 1. App Launch
      await tester.pumpWidget(const RedLetterApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify Impression Mode
      expect(find.text('Matthew 5:44'), findsWidgets);
      expect(
        find.text('Love your enemies and pray for those who persecute you'),
        findsOneWidget,
      );

      // Advance to Reflection
      await tester.tap(find.text('Continue').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Matthew 5:44'), findsWidgets);

      // Input Reflection
      await tester.enterText(
        find.byType(TextField).last,
        'Meaningful reflection',
      );
      await tester.pump();
      await tester.tap(find.text('Continue').last);
      await tester.pump(); // Transition to Scaffolding
      await tester.pump(const Duration(milliseconds: 600)); // Finish transition
      expect(find.text('Matthew 5:44'), findsWidgets);

      // Scaffolding Mode
      // We need to type hidden words.
      // The demo passage is "Love your enemies and pray for those who persecute you".
      // WordOcclusion is random, but we can't easily deterministic-ize it in an E2E test without dependency injection or mocking.
      // However, we refactored Scaffolding to work by typing words.
      // If we type the *entire* passage, we will definitely hit all hidden words.
      final fullText = 'Love your enemies and pray for those who persecute you';
      await tester.enterText(find.byType(TextField).last, fullText);
      await tester.pump();

      // Wait for completion check (which should be immediate if we typed it all)
      // The Continue button should be enabled.
      await tester.tap(find.text('Continue').last);
      await tester.pump(); // Transition out of Scaffolding
      await tester.pump(const Duration(milliseconds: 600)); // Finish transition
      expect(find.text('Matthew 5:44'), findsWidgets);

      // Prompted Mode (Lenient)
      // "love your enemies..." (lower case, no punctuation)
      await tester.enterText(
        find.byType(TextField).last,
        'love your enemies and pray for those who persecute you',
      );
      await tester.pump();
      await tester.tap(find.text('Continue').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Matthew 5:44'), findsWidgets);

      // Reconstruction Mode (Strict)
      // Must match exactly (case insensitive but punctuation sensitive? logic said strict match).
      // Wait, PassageValidator.isStrictMatch uses trim().toLowerCase() == input.trim().toLowerCase().
      // It respects punctuation in the string but ignores case.
      // So 'Love... you' vs 'love... you' is fine.
      // But 'you' vs 'you.' (if original had dot?).
      // The passage passage in main.dart:
      // text: 'Love your enemies and pray for those who persecute you', (No trailing dot in the demo data!)
      // So no dot needed.
      await tester.enterText(
        find.byType(TextField).last,
        'Love your enemies and pray for those who persecute you',
      );
      await tester.pump();
      await tester.tap(find.text('Continue').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Should cycle back or show done state?
      // PracticeState.advanceMode() says:
      // if (nextMode != null) ... else ... finished.
      // If finished, it stays on last mode but marks as completed.
      // The MAIN UI doesn't handle "finished" state explicitly other than updating the overlay count.
      // Ideally it relies on the "Completed: 5/5" text.
      // Verify we have a reset button in the footer
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
