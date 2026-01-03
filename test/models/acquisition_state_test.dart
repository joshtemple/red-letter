import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/acquisition_state.dart';
import 'package:red_letter/models/cloze_occlusion.dart';

void main() {
  group('AcquisitionLevel', () {
    test('maps to correct ClozeRound', () {
      expect(
        AcquisitionLevel.randomWordPerClause.clozeRound,
        ClozeRound.randomWordPerClause,
      );
      expect(
        AcquisitionLevel.rotatingClauseDeletion.clozeRound,
        ClozeRound.rotatingClauseDeletion,
      );
      expect(
        AcquisitionLevel.firstTwoWordsScaffolding.clozeRound,
        ClozeRound.firstTwoWordsScaffolding,
      );
    });

    test('next() returns correct progression', () {
      expect(
        AcquisitionLevel.randomWordPerClause.next,
        AcquisitionLevel.rotatingClauseDeletion,
      );
      expect(
        AcquisitionLevel.rotatingClauseDeletion.next,
        AcquisitionLevel.firstTwoWordsScaffolding,
      );
      expect(
        AcquisitionLevel.firstTwoWordsScaffolding.next,
        null, // Max level
      );
    });

    test('previous() returns correct regression', () {
      expect(
        AcquisitionLevel.randomWordPerClause.previous,
        null, // Min level
      );
      expect(
        AcquisitionLevel.rotatingClauseDeletion.previous,
        AcquisitionLevel.randomWordPerClause,
      );
      expect(
        AcquisitionLevel.firstTwoWordsScaffolding.previous,
        AcquisitionLevel.rotatingClauseDeletion,
      );
    });
  });

  group('AcquisitionState', () {
    test('initial state starts at first level', () {
      final state = AcquisitionState.initial(totalClauses: 3);

      expect(state.currentLevel, AcquisitionLevel.randomWordPerClause);
      expect(state.currentClauseIndex, 0);
      expect(state.totalClauses, 3);
    });

    test('advance() progresses through levels', () {
      var state = AcquisitionState.initial(totalClauses: 2);

      // Start at Round 1
      expect(state.currentLevel, AcquisitionLevel.randomWordPerClause);

      // Advance to Round 2
      state = state.advance()!;
      expect(state.currentLevel, AcquisitionLevel.rotatingClauseDeletion);
      expect(state.currentClauseIndex, 0);
    });

    test('advance() rotates through clauses in Round 2', () {
      var state = AcquisitionState(
        currentLevel: AcquisitionLevel.rotatingClauseDeletion,
        currentClauseIndex: 0,
        totalClauses: 3,
      );

      // Advance through clauses
      state = state.advance()!;
      expect(state.currentLevel, AcquisitionLevel.rotatingClauseDeletion);
      expect(state.currentClauseIndex, 1);

      state = state.advance()!;
      expect(state.currentLevel, AcquisitionLevel.rotatingClauseDeletion);
      expect(state.currentClauseIndex, 2);

      // After last clause, advance to Round 3
      state = state.advance()!;
      expect(state.currentLevel, AcquisitionLevel.firstTwoWordsScaffolding);
      expect(state.currentClauseIndex, 0);
    });

    test('advance() returns null when completed', () {
      final state = AcquisitionState(
        currentLevel: AcquisitionLevel.firstTwoWordsScaffolding,
        totalClauses: 2,
      );

      final nextState = state.advance();
      expect(nextState, null);
    });

    test('stepBack() regresses to previous level', () {
      var state = AcquisitionState(
        currentLevel: AcquisitionLevel.firstTwoWordsScaffolding,
        totalClauses: 2,
      );

      // Step back to Round 2
      state = state.stepBack()!;
      expect(state.currentLevel, AcquisitionLevel.rotatingClauseDeletion);
      expect(state.currentClauseIndex, 0); // Reset clause index

      // Step back to Round 1
      state = state.stepBack()!;
      expect(state.currentLevel, AcquisitionLevel.randomWordPerClause);
    });

    test('stepBack() returns null at minimum level', () {
      final state = AcquisitionState.initial(totalClauses: 2);
      final previousState = state.stepBack();

      expect(previousState, null);
    });

    test('isComplete returns true only at final level', () {
      expect(
        AcquisitionState.initial(totalClauses: 2).isComplete,
        false,
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.rotatingClauseDeletion,
          totalClauses: 2,
        ).isComplete,
        false,
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.firstTwoWordsScaffolding,
          totalClauses: 2,
        ).isComplete,
        true,
      );
    });

    test('canStepBack returns correct value', () {
      expect(
        AcquisitionState.initial(totalClauses: 2).canStepBack,
        false, // At minimum
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.rotatingClauseDeletion,
          totalClauses: 2,
        ).canStepBack,
        true,
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.firstTwoWordsScaffolding,
          totalClauses: 2,
        ).canStepBack,
        true,
      );
    });

    test('canAdvance returns correct value', () {
      expect(
        AcquisitionState.initial(totalClauses: 2).canAdvance,
        true,
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.rotatingClauseDeletion,
          currentClauseIndex: 0,
          totalClauses: 3,
        ).canAdvance,
        true, // More clauses to rotate through
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.rotatingClauseDeletion,
          currentClauseIndex: 2,
          totalClauses: 3,
        ).canAdvance,
        true, // Can advance to next round
      );

      expect(
        AcquisitionState(
          currentLevel: AcquisitionLevel.firstTwoWordsScaffolding,
          totalClauses: 2,
        ).canAdvance,
        false, // At maximum
      );
    });
  });
}
