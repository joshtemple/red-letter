import 'package:red_letter/models/cloze_occlusion.dart';

/// Represents the current sub-level within Scaffolding Mode (Mastery Level 2).
///
/// The acquisition ladder has 3 progressive rounds:
/// 1. Random word removal per clause (easiest)
/// 2. Rotating clause deletion (medium)
/// 3. First-2-words scaffolding (hardest)
///
/// Users progress forward on success and can step back on failure.
enum AcquisitionLevel {
  /// Round 1: Random word removal (1-2 words per clause)
  randomWordPerClause(0),

  /// Round 2: Rotating clause deletion (hide entire clauses)
  rotatingClauseDeletion(1),

  /// Round 3: First-2-words scaffolding (structural recall)
  firstTwoWordsScaffolding(2);

  const AcquisitionLevel(this.level);

  final int level;

  /// Gets the corresponding ClozeRound for this acquisition level.
  ClozeRound get clozeRound {
    switch (this) {
      case AcquisitionLevel.randomWordPerClause:
        return ClozeRound.randomWordPerClause;
      case AcquisitionLevel.rotatingClauseDeletion:
        return ClozeRound.rotatingClauseDeletion;
      case AcquisitionLevel.firstTwoWordsScaffolding:
        return ClozeRound.firstTwoWordsScaffolding;
    }
  }

  /// Returns the next level in the progression (or null if at max).
  AcquisitionLevel? get next {
    switch (this) {
      case AcquisitionLevel.randomWordPerClause:
        return AcquisitionLevel.rotatingClauseDeletion;
      case AcquisitionLevel.rotatingClauseDeletion:
        return AcquisitionLevel.firstTwoWordsScaffolding;
      case AcquisitionLevel.firstTwoWordsScaffolding:
        return null; // Max level
    }
  }

  /// Returns the previous level in the progression (or null if at min).
  AcquisitionLevel? get previous {
    switch (this) {
      case AcquisitionLevel.randomWordPerClause:
        return null; // Min level
      case AcquisitionLevel.rotatingClauseDeletion:
        return AcquisitionLevel.randomWordPerClause;
      case AcquisitionLevel.firstTwoWordsScaffolding:
        return AcquisitionLevel.rotatingClauseDeletion;
    }
  }

  String get displayName {
    switch (this) {
      case AcquisitionLevel.randomWordPerClause:
        return 'Random Word Removal';
      case AcquisitionLevel.rotatingClauseDeletion:
        return 'Clause Deletion';
      case AcquisitionLevel.firstTwoWordsScaffolding:
        return 'Structural Recall';
    }
  }
}

/// Manages progression through the acquisition ladder within Scaffolding Mode.
///
/// Tracks which round the user is on and handles:
/// - Advancement on successful completion
/// - Regression on failure (step back to easier round)
/// - Completion detection (finished all rounds)
class AcquisitionState {
  final AcquisitionLevel currentLevel;

  /// For Round 2 (rotating clause deletion): which clause is currently being tested
  final int currentClauseIndex;

  /// Total number of clauses in the passage (for Round 2 rotation)
  final int totalClauses;

  const AcquisitionState({
    required this.currentLevel,
    this.currentClauseIndex = 0,
    this.totalClauses = 0,
  });

  /// Creates an initial state for starting the acquisition ladder.
  factory AcquisitionState.initial({int totalClauses = 0}) {
    return AcquisitionState(
      currentLevel: AcquisitionLevel.randomWordPerClause,
      currentClauseIndex: 0,
      totalClauses: totalClauses,
    );
  }

  /// Advances to the next level on successful completion.
  ///
  /// Returns null if already at the maximum level (all rounds completed).
  AcquisitionState? advance() {
    // Special handling for Round 2 (rotating clause deletion)
    if (currentLevel == AcquisitionLevel.rotatingClauseDeletion) {
      final nextClauseIndex = currentClauseIndex + 1;

      // If we haven't completed all clauses yet, rotate to next clause
      if (nextClauseIndex < totalClauses) {
        return copyWith(currentClauseIndex: nextClauseIndex);
      }

      // Otherwise, advance to next round
    }

    final nextLevel = currentLevel.next;
    if (nextLevel == null) {
      return null; // Completed all rounds
    }

    return copyWith(
      currentLevel: nextLevel,
      currentClauseIndex: 0, // Reset for next round
    );
  }

  /// Steps back to the previous level on failure.
  ///
  /// Returns null if already at the minimum level (can't go back further).
  AcquisitionState? stepBack() {
    final previousLevel = currentLevel.previous;
    if (previousLevel == null) {
      return null; // Already at minimum level
    }

    return copyWith(
      currentLevel: previousLevel,
      currentClauseIndex: 0, // Reset clause rotation
    );
  }

  /// Returns true if the user has completed all acquisition rounds.
  bool get isComplete {
    return currentLevel == AcquisitionLevel.firstTwoWordsScaffolding &&
        currentLevel.next == null;
  }

  /// Returns true if the user can step back further.
  bool get canStepBack {
    return currentLevel.previous != null;
  }

  /// Returns true if the user can advance further.
  bool get canAdvance {
    if (currentLevel == AcquisitionLevel.rotatingClauseDeletion) {
      // Can advance if we have more clauses to rotate through
      return currentClauseIndex < totalClauses - 1 || currentLevel.next != null;
    }

    return currentLevel.next != null;
  }

  AcquisitionState copyWith({
    AcquisitionLevel? currentLevel,
    int? currentClauseIndex,
    int? totalClauses,
  }) {
    return AcquisitionState(
      currentLevel: currentLevel ?? this.currentLevel,
      currentClauseIndex: currentClauseIndex ?? this.currentClauseIndex,
      totalClauses: totalClauses ?? this.totalClauses,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AcquisitionState &&
        other.currentLevel == currentLevel &&
        other.currentClauseIndex == currentClauseIndex &&
        other.totalClauses == totalClauses;
  }

  @override
  int get hashCode {
    return Object.hash(currentLevel, currentClauseIndex, totalClauses);
  }

  @override
  String toString() {
    return 'AcquisitionState(level: ${currentLevel.displayName}, clause: $currentClauseIndex/$totalClauses)';
  }
}
