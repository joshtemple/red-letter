import 'passage.dart';
import 'clause_segmentation.dart';

/// Represents a step in a practice session.
///
/// Session Hierarchy: Session → Flow → Steps → Scaffolding → Levels → Rounds → Lives
///
/// Steps are the main sequential progression in a practice session:
/// 1. Impression - Full text + visual mnemonic
/// 2. Reflection - Semantic understanding prompt
/// 3. Scaffolding - Progressive cloze deletion with 4 levels:
///    - L1: randomWords
///    - L2: firstTwoWords
///    - L3: rotatingClauses
///    - L4: fullPassage
enum PracticeStep {
  impression,
  reflection,
  randomWords, // L1: A few words deleted (N rounds)
  firstTwoWords, // L2: First 2 words of each clause shown (1 round)
  rotatingClauses, // L3: One clause deleted at a time (M rounds, M = # clauses)
  fullPassage; // L4: 100% cloze deletion, no underlines (1 round)

  String get displayName {
    switch (this) {
      case PracticeStep.impression:
        return 'Impression';
      case PracticeStep.reflection:
        return 'Reflection';
      case PracticeStep.randomWords:
        return 'Scaffolding L1: Random Words';
      case PracticeStep.firstTwoWords:
        return 'Scaffolding L2: First Two Words';
      case PracticeStep.rotatingClauses:
        return 'Scaffolding L3: Rotating Clauses';
      case PracticeStep.fullPassage:
        return 'Scaffolding L4: Full Passage';
    }
  }

  String get description {
    switch (this) {
      case PracticeStep.impression:
        return 'Full text + visual mnemonic display';
      case PracticeStep.reflection:
        return 'Mandatory reflection prompt (semantic encoding)';
      case PracticeStep.randomWords:
        return '1-2 random non-trivial words removed per clause';
      case PracticeStep.firstTwoWords:
        return 'Only the first 2 words of each clause shown';
      case PracticeStep.rotatingClauses:
        return 'One entire clause hidden (rotating)';
      case PracticeStep.fullPassage:
        return 'Total independent recall (100% cloze deletion)';
    }
  }

  /// Returns the next step in the sequence, or null if this is the final step.
  /// Note: Reflection step is currently disabled and will be skipped.
  PracticeStep? get next {
    final index = PracticeStep.values.indexOf(this);
    if (index < PracticeStep.values.length - 1) {
      final nextStep = PracticeStep.values[index + 1];
      // Skip reflection step (disabled)
      if (nextStep == PracticeStep.reflection) {
        return nextStep.next;
      }
      return nextStep;
    }
    return null;
  }

  /// Returns true if this step is part of scaffolding (has levels and rounds).
  bool get isScaffolding {
    return this == PracticeStep.randomWords ||
        this == PracticeStep.firstTwoWords ||
        this == PracticeStep.rotatingClauses ||
        this == PracticeStep.fullPassage;
  }

  /// Returns the scaffolding level (L1-L4) for scaffolding steps.
  ScaffoldingLevel? get scaffoldingLevel {
    switch (this) {
      case PracticeStep.randomWords:
        return ScaffoldingLevel.l1;
      case PracticeStep.firstTwoWords:
        return ScaffoldingLevel.l2;
      case PracticeStep.rotatingClauses:
        return ScaffoldingLevel.l3;
      case PracticeStep.fullPassage:
        return ScaffoldingLevel.l4;
      default:
        return null;
    }
  }
}

/// Represents a scaffolding level within the scaffolding step.
///
/// Scaffolding uses progressive cloze deletion across 4 levels:
/// - L1: Random words (repeat N rounds)
/// - L2: First two words (1 round)
/// - L3: Rotating clauses (M rounds, M = # of clauses)
/// - L4: Full passage (1 round, no underlines)
///
/// Each round has 2 lives. Completing a round advances to the next round/level.
/// Losing all lives regresses one level (L1 stays at L1).
enum ScaffoldingLevel {
  l1, // randomWords
  l2, // firstTwoWords
  l3, // rotatingClauses
  l4; // fullPassage

  String get displayName {
    switch (this) {
      case ScaffoldingLevel.l1:
        return 'Level 1: Random Words';
      case ScaffoldingLevel.l2:
        return 'Level 2: First Two Words';
      case ScaffoldingLevel.l3:
        return 'Level 3: Rotating Clauses';
      case ScaffoldingLevel.l4:
        return 'Level 4: Full Passage';
    }
  }

  /// Returns the corresponding PracticeStep for this level.
  PracticeStep get step {
    switch (this) {
      case ScaffoldingLevel.l1:
        return PracticeStep.randomWords;
      case ScaffoldingLevel.l2:
        return PracticeStep.firstTwoWords;
      case ScaffoldingLevel.l3:
        return PracticeStep.rotatingClauses;
      case ScaffoldingLevel.l4:
        return PracticeStep.fullPassage;
    }
  }

  /// Returns the next level, or null if this is L4.
  ScaffoldingLevel? get next {
    final index = ScaffoldingLevel.values.indexOf(this);
    if (index < ScaffoldingLevel.values.length - 1) {
      return ScaffoldingLevel.values[index + 1];
    }
    return null;
  }

  /// Returns the previous level for regression, or null if this is L1.
  ScaffoldingLevel? get previous {
    final index = ScaffoldingLevel.values.indexOf(this);
    if (index > 0) {
      return ScaffoldingLevel.values[index - 1];
    }
    return null; // L1 stays at L1
  }

  /// Returns the total number of rounds for this level.
  int getTotalRounds(Passage passage) {
    switch (this) {
      case ScaffoldingLevel.l1:
        return 3; // Fixed 3 rounds
      case ScaffoldingLevel.l2:
        return 1;
      case ScaffoldingLevel.l3:
        return ClauseSegmentation.fromPassage(passage).clauseCount;
      case ScaffoldingLevel.l4:
        return 1;
    }
  }
}
