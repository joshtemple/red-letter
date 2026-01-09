import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_step.dart';
import 'package:red_letter/models/practice_state.dart';

void main() {
  group('Passage Tests', () {
    test('should create instance from text', () {
      final p = Passage.fromText(
        id: '1',
        text: 'Jesus wept.',
        reference: 'John 11:35',
      );
      expect(p.id, '1');
      expect(p.words, ['Jesus', 'wept.']);
    });
  });

  group('PracticeState Tests', () {
    test('should progress through modes', () {
      final p = Passage.fromText(id: '1', text: 'Test', reference: 'Ref');
      var state = PracticeState.initial(p);

      expect(state.currentStep, PracticeStep.impression);

      // Advance to Scaffolding (skipping disabled Reflection step)
      state = state.advanceStep();
      expect(state.currentStep, PracticeStep.randomWords);
      expect(state.completedSteps, contains(PracticeStep.impression));

      // Advance to Rotating Clauses
      state = state.advanceStep();
      expect(state.currentStep, PracticeStep.rotatingClauses);

      // Advance to First Two Words
      state = state.advanceStep();
      expect(state.currentStep, PracticeStep.firstTwoWords);

      // Advance to Full Passage
      state = state.advanceStep();
      expect(state.currentStep, PracticeStep.fullPassage);

      // Finish
      state = state.advanceStep();

      expect(state.isComplete, true);
      // Reflection is skipped, so only 5 steps completed
      expect(state.completedSteps.length, 5);
      expect(state.completedSteps, contains(PracticeStep.impression));
      expect(state.completedSteps, contains(PracticeStep.randomWords));
      expect(state.completedSteps, contains(PracticeStep.firstTwoWords));
      expect(state.completedSteps, contains(PracticeStep.rotatingClauses));
      expect(state.completedSteps, contains(PracticeStep.fullPassage));
    });

    test('reset should return to initial state', () {
      final p = Passage.fromText(id: '1', text: 'Test', reference: 'Ref');
      var state = PracticeState.initial(p);
      state = state.advanceStep(); // Reflection

      state = state.reset();
      expect(state.currentStep, PracticeStep.impression);
      expect(state.completedSteps, isEmpty);
    });

    test('should allow custom initial mode and reset to it', () {
      final p = Passage.fromText(id: '1', text: 'Test', reference: 'Ref');
      var state = PracticeState.initial(
        p,
        initialStep: PracticeStep.randomWords,
      );

      expect(state.currentStep, PracticeStep.randomWords);
      expect(state.sessionStartStep, PracticeStep.randomWords);

      state = state.advanceStep(); // Rotating Clauses
      expect(state.currentStep, PracticeStep.rotatingClauses);

      state = state.reset();
      expect(state.currentStep, PracticeStep.randomWords);
      expect(state.sessionStartStep, PracticeStep.randomWords);
    });
  });
}
