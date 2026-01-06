import 'passage.dart';
import 'practice_step.dart';
import 'session_flow_type.dart';

/// Represents the state of a practice session.
///
/// Session Hierarchy: Session → Flow → Steps → Scaffolding → Levels → Rounds → Lives
class PracticeState {
  final Passage currentPassage;
  final PracticeStep currentStep;
  final PracticeStep sessionStartStep;
  final String userInput;
  final DateTime startTime;
  final Set<PracticeStep> completedSteps;

  final FlowType flowType;
  // Scaffolding-specific state
  final ScaffoldingLevel? currentLevel; // L1-L4 for scaffolding steps
  final int currentRound; // Which round within the current level (0-indexed)
  final Set<int>
  failedWordIndices; // Word indices failed/revealed across session

  const PracticeState({
    required this.currentPassage,
    this.currentStep = PracticeStep.impression,
    this.sessionStartStep = PracticeStep.impression,
    this.flowType = FlowType.learning,
    this.userInput = '',
    required this.startTime,
    this.completedSteps = const {},
    this.currentLevel,
    this.currentRound = 0,
    this.failedWordIndices = const {},
  });

  /// Creates an initial state for a passage
  factory PracticeState.initial(
    Passage passage, {
    PracticeStep initialStep = PracticeStep.impression,
    FlowType flowType = FlowType.learning,
  }) {
    return PracticeState(
      currentPassage: passage,
      currentStep: initialStep,
      sessionStartStep: initialStep,
      flowType: flowType,
      startTime: DateTime.now(),
      currentLevel: initialStep.scaffoldingLevel,
      currentRound: 0,
    );
  }

  /// Progresses to the next step.
  /// If there is no next step (finished), it effectively stays in the last step
  /// but adds it to completed.
  PracticeState advanceStep() {
    final nextStep = currentStep.next;

    // Mark current step as completed
    final newCompleted = Set<PracticeStep>.from(completedSteps)
      ..add(currentStep);

    if (nextStep != null) {
      return copyWith(
        currentStep: nextStep,
        completedSteps: newCompleted,
        userInput: '', // Reset input for next step
        currentLevel: nextStep.scaffoldingLevel,
        currentRound: 0, // Reset round for new step/level
      );
    } else {
      // Finished all steps
      return copyWith(completedSteps: newCompleted);
    }
  }

  /// Advances to the next round within the current scaffolding level.
  /// Resets lives to 2 for the new round.
  PracticeState advanceRound() {
    return copyWith(currentRound: currentRound + 1, userInput: '');
  }

  /// Advances to the next scaffolding level (L1→L2→L3→L4).
  /// Resets round to 0 and lives to 2.
  PracticeState advanceLevel() {
    final nextLevel = currentLevel?.next;
    if (nextLevel == null) {
      // At L4 or not in scaffolding, advance step instead
      return advanceStep();
    }

    return copyWith(
      currentStep: nextLevel.step,
      currentLevel: nextLevel,
      currentRound: 0,
      userInput: '',
    );
  }

  /// Regresses one scaffolding level (L4→L3→L2→L1, L1 stays at L1).
  /// Resets to round 0 of the regressed level with 2 lives.
  PracticeState regressLevel() {
    final prevLevel = currentLevel?.previous;
    if (prevLevel == null) {
      // At L1 or not in scaffolding, stay at current level but reset round
      return copyWith(currentRound: 0, userInput: '');
    }

    return copyWith(
      currentStep: prevLevel.step,
      currentLevel: prevLevel,
      currentRound: 0,
      userInput: '',
    );
  }

  /// Adds word indices to the failed words set.
  PracticeState recordFailedWords(Set<int> wordIndices) {
    return copyWith(
      failedWordIndices: Set<int>.from(failedWordIndices)..addAll(wordIndices),
    );
  }

  /// Resets the practice session for the current passage
  PracticeState reset() {
    return PracticeState.initial(
      currentPassage,
      initialStep: sessionStartStep,
      flowType: flowType,
    );
  }

  /// Updates the user input for the current step
  PracticeState copyWith({
    Passage? currentPassage,
    PracticeStep? currentStep,
    PracticeStep? sessionStartStep,
    FlowType? flowType,
    String? userInput,
    DateTime? startTime,
    Set<PracticeStep>? completedSteps,
    ScaffoldingLevel? currentLevel,
    int? currentRound,
    Set<int>? failedWordIndices,
  }) {
    return PracticeState(
      currentPassage: currentPassage ?? this.currentPassage,
      currentStep: currentStep ?? this.currentStep,
      sessionStartStep: sessionStartStep ?? this.sessionStartStep,
      flowType: flowType ?? this.flowType,
      userInput: userInput ?? this.userInput,
      startTime: startTime ?? this.startTime,
      completedSteps: completedSteps ?? this.completedSteps,
      currentLevel: currentLevel ?? this.currentLevel,
      currentRound: currentRound ?? this.currentRound,
      failedWordIndices: failedWordIndices ?? this.failedWordIndices,
    );
  }

  /// Updates the user input for the current step
  PracticeState updateInput(String input) {
    return copyWith(userInput: input);
  }

  /// Returns true if all steps have been completed
  /// Note: Reflection step is currently disabled and skipped
  bool get isComplete {
    // Reflection is skipped, so we need one fewer step to complete
    return completedSteps.length == PracticeStep.values.length - 1;
  }

  /// Returns the elapsed time since the practice session started
  Duration get elapsedTime {
    return DateTime.now().difference(startTime);
  }

  /// Returns true if currently in a scaffolding step
  bool get isScaffolding {
    return currentStep.isScaffolding;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PracticeState &&
        other.currentPassage == currentPassage &&
        other.currentStep == currentStep &&
        other.sessionStartStep == sessionStartStep &&
        other.flowType == flowType &&
        other.userInput == userInput &&
        other.startTime == startTime &&
        _setEquals(other.completedSteps, completedSteps) &&
        other.currentLevel == currentLevel &&
        other.currentRound == currentRound &&
        _setEquals(
          other.failedWordIndices.cast<Object>(),
          failedWordIndices.cast<Object>(),
        );
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPassage,
      currentStep,
      sessionStartStep,
      flowType,
      userInput,
      startTime,
      Object.hashAllUnordered(completedSteps),
      currentLevel,
      currentRound,
      Object.hashAllUnordered(failedWordIndices),
    );
  }

  bool _setEquals(Set<Object> a, Set<Object> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  String toString() {
    final levelInfo = currentLevel != null
        ? ' L${currentLevel!.name.substring(1)}'
        : '';
    final roundInfo = isScaffolding ? ' R${currentRound + 1}' : '';
    return 'PracticeState(step: ${currentStep.name}$levelInfo$roundInfo, input: "$userInput", completed: ${completedSteps.length})';
  }
}
