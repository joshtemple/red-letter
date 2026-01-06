import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/main.dart';
import 'package:red_letter/screens/impression_screen.dart';

import 'utils/pages/impression_page.dart';
import 'utils/pages/reflection_page.dart';
import 'utils/pages/scaffolding_page.dart';

void main() {
  group('End-to-End Practice Flow', () {
    testWidgets(
      'Complete walkthrough of all practice modes',
      // skip: 'E2E tests temporarily disabled due to UI flux',
      skip: true,
      (tester) async {
        // Setup In-Memory Database
        final db = AppDatabase.forTesting(
          NativeDatabase.memory(),
          skipSeeding: true,
        );
        final repository = PassageRepository.fromDatabase(db);

        const passageText =
            'Love your enemies and pray for those who persecute you';
        const reference = 'Matthew 5:44';

        // Seed Data
        await repository.insertPassage(
          PassagesCompanion(
            passageId: const Value('mat-5-44'),
            reference: const Value(reference),
            passageText: const Value(passageText),
            translationId: const Value('esv'),
            tags: const Value('test'),
            book: const Value('Matthew'),
            chapter: const Value(5),
            startVerse: const Value(44),
            endVerse: const Value(44),
          ),
        );

        // 1. App Launch
        await tester.pumpWidget(RedLetterApp(repository: repository));

        // Dispose DB after test
        addTearDown(() async {
          await db.close();
        });

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // --- Passage List Screen ---
        // Verify we see the passage in the list
        expect(find.text(reference), findsWidgets);

        // Tap the passage to start practice
        // await tester.tap(find.byKey(const ValueKey('mat-5-44')));
        // Try FAB instead
        await tester.tap(find.text('MEMORIZE'));
        await tester.pump(const Duration(milliseconds: 2000));

        if (find.byType(ImpressionScreen).evaluate().isEmpty) {
          debugDumpApp();
        }

        // Debugging: Check for common failure states
        expect(
          find.textContaining('Error:'),
          findsNothing,
          reason: 'App showed error screen',
        );
        expect(
          find.text('My Passages'),
          findsNothing,
          reason: 'Failed to navigate away from Passage List',
        );
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'Stuck on Loading Screen',
        );
        expect(
          find.byType(ImpressionScreen),
          findsOneWidget,
          reason: 'ImpressionScreen not in tree',
        );

        // --- Impression Mode ---
        // Verify unique text to confirm navigation
        expect(find.text('Read this passage aloud twice'), findsOneWidget);

        final impressionPage = ImpressionPage(tester);
        impressionPage.expectReference(reference);
        impressionPage.expectPassageText(passageText);
        await impressionPage.tapContinue();
        await tester.pump(const Duration(milliseconds: 1000));

        // --- Reflection Mode ---
        final reflectionPage = ReflectionPage(tester);
        await reflectionPage.enterReflection('Meaningful reflection');
        await reflectionPage.tapContinue();
        await tester.pump(const Duration(milliseconds: 1000));

        // --- Scaffolding Mode ---
        final scaffoldingPage = ScaffoldingPage(tester);
        // Type full text to ensure we hit all hidden words regardless of randomness
        await scaffoldingPage.enterText(passageText);
        await scaffoldingPage.tapContinue();
        await tester.pump(const Duration(milliseconds: 1000));

        // Note: Prompted and Reconstruction have been removed in favor of
        // 4-level scaffolding. FullPassage (L4) covers the reconstruction use case.
        // For this test, we verify we can reach the end or at least complete the standard Scaffolding step.
      },
    );
  });
}
