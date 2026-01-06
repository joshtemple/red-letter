import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/controllers/practice_controller.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_step.dart';

void main() {
  group('PracticeController Tests', () {
    late PracticeController controller;
    late Passage testPassage;
    PracticeStep? lastCompletedStep;
    String? lastInput;

    setUp(() {
      testPassage = const Passage(
        id: 'test-1',
        text: 'Test Passage',
        reference: 'Test 1:1',
        words: [],
      );

      lastCompletedStep = null;
      lastInput = null;

      controller = PracticeController(
        testPassage,
        onStepComplete: (mode, input) {
          lastCompletedStep = mode;
          lastInput = input;
        },
      );
    });

    test('Initial state is correct', () {
      expect(controller.value.currentStep, PracticeStep.impression);
      expect(controller.value.currentPassage.id, testPassage.id);
    });

    test('Advancing emits callback and changes mode', () {
      // Advance from Impression
      controller.advance();
      expect(lastCompletedStep, PracticeStep.impression);
      expect(controller.value.currentStep, PracticeStep.reflection);

      // Advance from Reflection
      controller.advance('My reflection');
      expect(lastCompletedStep, PracticeStep.reflection);
      expect(lastInput, 'My reflection');
      expect(controller.value.currentStep, PracticeStep.randomWords);
    });

    test('JumpTo changes step and resets input', () {
      controller.jumpTo(PracticeStep.fullPassage);
      expect(controller.value.currentStep, PracticeStep.fullPassage);
      expect(controller.value.userInput, isEmpty);
      expect(controller.value.currentLevel, ScaffoldingLevel.l4);
    });

    test('Regress moves back one scaffolding level', () {
      // L4 -> L3
      controller.jumpTo(PracticeStep.fullPassage);
      controller.regress();
      expect(controller.value.currentStep, PracticeStep.rotatingClauses);
      expect(controller.value.currentLevel, ScaffoldingLevel.l3);

      // L3 -> L2
      controller.regress();
      expect(controller.value.currentStep, PracticeStep.firstTwoWords);
      expect(controller.value.currentLevel, ScaffoldingLevel.l2);

      // L2 -> L1
      controller.regress();
      expect(controller.value.currentStep, PracticeStep.randomWords);
      expect(controller.value.currentLevel, ScaffoldingLevel.l1);

      // L1 stays at L1
      controller.regress();
      expect(controller.value.currentStep, PracticeStep.randomWords);
      expect(controller.value.currentLevel, ScaffoldingLevel.l1);
    });
  });
}
