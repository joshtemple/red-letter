import 'package:red_letter/models/session_flow_type.dart';
import 'package:flutter/foundation.dart';

import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_step.dart';
import 'package:red_letter/models/practice_state.dart';

/// Controller for managing practice session state using ValueNotifier pattern.
///
/// Session Hierarchy: Session → Flow → Steps → Scaffolding → Levels → Rounds → Lives
class PracticeController extends ValueNotifier<PracticeState> {
  // Callback for when a step is completed (for persistence in parent)
  final Function(PracticeStep step, String? input)? onStepComplete;

  PracticeController(
    Passage passage, {
    this.onStepComplete,
    PracticeStep initialStep = PracticeStep.impression,
    FlowType flowType = FlowType.learning,
  }) : super(
         PracticeState.initial(
           passage,
           initialStep: initialStep,
           flowType: flowType,
         ),
       );

  /// Advances to the next step in the session.
  /// For non-scaffolding steps, this moves to the next step.
  /// For scaffolding steps, use advanceRound() or advanceLevel() instead.
  void advance([String? input]) {
    final currentStep = value.currentStep;

    // Scaffolding progression logic
    if (value.isScaffolding) {
      final currentLevel = value.currentLevel;
      // Scaffolding steps MUST have a level, but check for safety
      if (currentLevel != null) {
        final totalRounds = currentLevel.getTotalRounds(value.currentPassage);

        // If rounds remain in this level, advance round (don't notify step completion)
        if (value.currentRound < totalRounds - 1) {
          advanceRound();
          if (input != null) {
            value = value.updateInput(
              input,
            ); // Preserve input if needed? Usually cleared on round change
          }
          return;
        } else {
          // Level complete - all rounds done, notify parent of step completion
          onStepComplete?.call(currentStep, input);

          // Advance to next level (or next step if L4)
          advanceLevel();
          if (input != null) {
            value = value.updateInput(input);
          }
          return;
        }
      }
    }

    // Standard progression for non-scaffolding steps
    // Notify parent of step completion
    onStepComplete?.call(currentStep, input);

    final nextState = value.advanceStep();
    value = nextState;

    if (input != null) {
      value = value.updateInput(input);
    }
  }

  /// Advances to the next round within the current scaffolding level.
  /// Resets lives to 2 for the new round.
  void advanceRound() {
    value = value.advanceRound();
  }

  /// Advances to the next scaffolding level (L1→L2→L3→L4).
  /// After L4, advances to the next step.
  void advanceLevel() {
    value = value.advanceLevel();
  }

  /// Regresses one scaffolding level (L4→L3→L2→L1, L1 stays at L1).
  /// Used when user runs out of lives in a round.
  /// Resets to round 0 of the regressed level.
  void regress() {
    value = value.regressLevel();
  }

  /// Records word indices that the user failed or revealed.
  void recordFailedWords(Set<int> wordIndices) {
    value = value.recordFailedWords(wordIndices);
  }

  /// Forces a jump to a specific step
  void jumpTo(PracticeStep step) {
    value = value.copyWith(
      currentStep: step,
      userInput: '', // Reset input on jump
      currentLevel: step.scaffoldingLevel,
      currentRound: 0,
    );
  }

  /// Resets the entire practice session
  void reset() {
    value = value.reset();
  }
}
