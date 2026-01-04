import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/controllers/practice_controller.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';

void main() {
  group('PracticeController Tests', () {
    late PracticeController controller;
    late Passage testPassage;
    PracticeMode? lastCompletedStep;
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
      expect(controller.value.currentMode, PracticeMode.impression);
      expect(controller.value.currentPassage.id, testPassage.id);
    });

    test('Advancing emits callback and changes mode', () {
      // Advance from Impression
      controller.advance();
      expect(lastCompletedStep, PracticeMode.impression);
      expect(controller.value.currentMode, PracticeMode.reflection);

      // Advance from Reflection
      controller.advance('My reflection');
      expect(lastCompletedStep, PracticeMode.reflection);
      expect(lastInput, 'My reflection');
      expect(controller.value.currentMode, PracticeMode.randomWords);
    });

    test('JumpTo changes mode and resets input', () {
      controller.jumpTo(PracticeMode.prompted);
      expect(controller.value.currentMode, PracticeMode.prompted);
      expect(controller.value.userInput, isEmpty);
    });

    test('Regress moves back correctly', () {
      controller.jumpTo(PracticeMode.prompted);
      controller.regress();
      expect(controller.value.currentMode, PracticeMode.randomWords);

      controller.jumpTo(PracticeMode.reconstruction);
      controller.regress();
      expect(controller.value.currentMode, PracticeMode.prompted);
    });
  });
}
