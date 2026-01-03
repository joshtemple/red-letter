import 'package:flutter/foundation.dart';

import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';

class PracticeController extends ValueNotifier<PracticeState> {
  // Callback for when a step is completed (for persistence in parent)
  final Function(PracticeMode mode, String? input)? onStepComplete;

  PracticeController(
    Passage passage, {
    this.onStepComplete,
    PracticeMode initialMode = PracticeMode.impression,
  }) : super(PracticeState.initial(passage, initialMode: initialMode));

  void advance([String? input]) {
    final currentMode = value.currentMode;

    // Notify parent of step completion
    onStepComplete?.call(currentMode, input);

    // Standard progression
    final nextState = value.advanceMode();
    value = nextState;

    if (input != null) {
      value = value.updateInput(input);
    }
  }

  /// Regresses the practice session to a previous mode
  /// Used for acquisition failure (e.g., Prompted -> Scaffolding)
  void regress() {
    PracticeMode? targetMode;
    switch (value.currentMode) {
      case PracticeMode.prompted:
        targetMode = PracticeMode.scaffolding;
        break;
      case PracticeMode.reconstruction:
        targetMode = PracticeMode.prompted;
        break;
      default:
        // No specific regression defined, stay or go back one step?
        // For now, do nothing if not defined.
        break;
    }

    if (targetMode != null) {
      jumpTo(targetMode);
    }
  }

  /// Forces a jump to a specific mode
  void jumpTo(PracticeMode mode) {
    value = value.copyWith(
      currentMode: mode,
      userInput: '', // Reset input on jump
    );
  }

  void reset() {
    value = value.reset();
  }
}
