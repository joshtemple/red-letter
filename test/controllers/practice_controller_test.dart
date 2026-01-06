import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/controllers/practice_controller.dart';
import 'package:red_letter/models/practice_step.dart';
import '../utils/builders/passage_builder.dart';

void main() {
  group('PracticeController Scaffolding Logic', () {
    test('L1 (RandomWords) should have 3 rounds', () {
      final passage = PassageBuilder().build();
      // Start at L1
      final controller = PracticeController(
        passage,
        initialStep: PracticeStep.randomWords,
      );

      // Round 0 -> Round 1
      controller.advance();
      expect(
        controller.value.currentRound,
        1,
        reason: 'Should advance to Round 1',
      );
      expect(controller.value.currentStep, PracticeStep.randomWords);

      // Round 1 -> Round 2
      controller.advance();
      expect(
        controller.value.currentRound,
        2,
        reason: 'Should advance to Round 2',
      );
      expect(controller.value.currentStep, PracticeStep.randomWords);

      // Round 2 -> L2 (FirstTwoWords)
      controller.advance();
      expect(
        controller.value.currentRound,
        0,
        reason: 'Should reset to Round 0',
      );
      expect(
        controller.value.currentStep,
        PracticeStep.firstTwoWords,
        reason: 'Should advance to L2',
      );
    });

    test('L3 (RotatingClauses) should adapt rounds to clause count', () {
      // Create passage with 2 clauses
      // Note: ClauseSegmentation typically splits by punctuation marks like period, question mark, exclamation.
      // Or comma/semicolon depending on implementation.
      // Let's assume standard implementation.
      final passage = PassageBuilder()
          .withText('Love your enemies. Pray for them.')
          .build();

      final controller = PracticeController(
        passage,
        initialStep: PracticeStep.rotatingClauses,
      );

      // Round 0 (Clause 0) -> Round 1 (Clause 1)
      controller.advance();
      expect(controller.value.currentRound, 1);
      expect(controller.value.currentStep, PracticeStep.rotatingClauses);

      // Round 1 (Clause 1) -> L4 (FullPassage)
      controller.advance();
      expect(controller.value.currentRound, 0);
      expect(controller.value.currentStep, PracticeStep.fullPassage);
    });

    test('Regress should move to previous level round 0', () {
      final passage = PassageBuilder().build();
      // Start at L2
      final controller = PracticeController(
        passage,
        initialStep: PracticeStep.firstTwoWords,
      );

      controller.regress();

      expect(
        controller.value.currentStep,
        PracticeStep.randomWords,
        reason: 'Should regress to L1',
      );
      expect(
        controller.value.currentRound,
        0,
        reason: 'Should reset to Round 0',
      );
    });

    test('Regress from L1 should stay at L1 Round 0', () {
      final passage = PassageBuilder().build();
      final controller = PracticeController(
        passage,
        initialStep: PracticeStep.randomWords,
      );

      // Advance to Round 1
      controller.advance();
      expect(controller.value.currentRound, 1);

      controller.regress();

      expect(controller.value.currentStep, PracticeStep.randomWords);
      expect(controller.value.currentRound, 0);
    });

    test('Advance from L4 to completion', () {
      final passage = PassageBuilder().build();
      final controller = PracticeController(
        passage,
        initialStep: PracticeStep.fullPassage,
      );

      // L4 has 1 round.
      controller.advance();

      expect(controller.value.currentStep, PracticeStep.fullPassage);
      expect(
        controller.value.completedSteps.contains(PracticeStep.fullPassage),
        true,
      );
    });
  });
}
