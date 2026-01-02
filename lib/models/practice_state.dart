import 'passage.dart';
import 'practice_mode.dart';

class PracticeState {
  final Passage currentPassage;
  final PracticeMode currentMode;
  final String userInput;
  final DateTime startTime;
  final Set<PracticeMode> completedModes;

  const PracticeState({
    required this.currentPassage,
    this.currentMode = PracticeMode.impression,
    this.userInput = '',
    required this.startTime,
    this.completedModes = const {},
  });

  /// Creates an initial state for a passage
  factory PracticeState.initial(Passage passage) {
    return PracticeState(
      currentPassage: passage,
      currentMode: PracticeMode.impression,
      startTime: DateTime.now(),
    );
  }

  PracticeState copyWith({
    Passage? currentPassage,
    PracticeMode? currentMode,
    String? userInput,
    DateTime? startTime,
    Set<PracticeMode>? completedModes,
  }) {
    return PracticeState(
      currentPassage: currentPassage ?? this.currentPassage,
      currentMode: currentMode ?? this.currentMode,
      userInput: userInput ?? this.userInput,
      startTime: startTime ?? this.startTime,
      completedModes: completedModes ?? this.completedModes,
    );
  }

  /// Progresses to the next mode.
  /// If there is no next mode (finished), it effectively stays in the last mode
  /// but adds it to completed.
  /// Logic can be refined to handle "finished" state explicitly if needed.
  PracticeState advanceMode() {
    final nextMode = currentMode.next;
    
    // Mark current mode as completed
    final newCompleted = Set<PracticeMode>.from(completedModes)..add(currentMode);

    if (nextMode != null) {
      return copyWith(
        currentMode: nextMode,
        completedModes: newCompleted,
        userInput: '', // Reset input for next mode
      );
    } else {
      // Finished all modes
      return copyWith(
        completedModes: newCompleted,
      );
    }
  }

  /// Resets the practice session for the current passage
  PracticeState reset() {
    return PracticeState.initial(currentPassage);
  }

  /// Updates the user input for the current mode
  PracticeState updateInput(String input) {
    return copyWith(userInput: input);
  }

  /// Returns true if all modes have been completed
  bool get isComplete {
    return completedModes.length == PracticeMode.values.length;
  }

  /// Returns the elapsed time since the practice session started
  Duration get elapsedTime {
    return DateTime.now().difference(startTime);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PracticeState &&
        other.currentPassage == currentPassage &&
        other.currentMode == currentMode &&
        other.userInput == userInput &&
        other.startTime == startTime &&
        _setEquals(other.completedModes, completedModes);
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPassage,
      currentMode,
      userInput,
      startTime,
      Object.hashAllUnordered(completedModes),
    );
  }

  bool _setEquals(Set<PracticeMode> a, Set<PracticeMode> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  String toString() {
    return 'PracticeState(mode: ${currentMode.name}, input: "$userInput", completed: ${completedModes.length})';
  }
}
