import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/database/app_database.dart';

/// Adapter that bridges Red Letter's domain model with the FSRS package.
///
/// Provides conversion between Drift's UserProgress data and FSRS Card objects,
/// enabling the use of the FSRS algorithm for spaced repetition scheduling.
///
/// The UserProgress table stores native FSRS fields (stability, difficulty,
/// step, state) which map directly to FSRS Card properties.
class FSRSAdapter {
  /// Convert UserProgress Drift data to an FSRS Card object.
  ///
  /// Direct mapping of FSRS fields:
  /// - passageId → cardId (hashed to int)
  /// - state → State enum
  /// - step → learning/relearning step
  /// - stability → memory stability
  /// - difficulty → inherent difficulty
  /// - nextReview → due
  /// - lastReviewed → lastReview
  static fsrs.Card toFSRSCard(UserProgress progress, {String? passageId}) {
    // Convert passageId string to int for FSRS cardId
    final cardId = (passageId ?? progress.passageId).hashCode;

    // Map integer state to FSRS State enum
    // 0 = learning, 1 = review, 2 = relearning
    final state = _intToState(progress.state);

    return fsrs.Card(
      cardId: cardId,
      state: state,
      step: progress.step,
      // Clamp stability to avoid division by zero (or 0 interval) in FSRS
      stability: (progress.stability <= 0.0) ? 1e-4 : progress.stability,
      // Clamp difficulty to valid FSRS range (1-10) to avoid negative difficulty
      difficulty: (progress.difficulty <= 0.0) ? 5.0 : progress.difficulty,
      due: progress.nextReview ?? DateTime.now(),
      lastReview: progress.lastReviewed,
    );
  }

  /// Convert an FSRS Card back to UserProgress companion for database updates.
  ///
  /// Direct mapping of FSRS fields back to database schema.
  /// Returns a UserProgressTableCompanion for use with Drift updates.
  ///
  /// If [previousMasteryLevel] is provided, the new mastery level will not
  /// regress below it unless the card enters the Relearning state (indicating failure).
  static UserProgressTableCompanion toUserProgressCompanion({
    required String passageId,
    required fsrs.Card card,
    int? previousMasteryLevel,
  }) {
    // Clamp stability to reasonable range (0-36500 days = ~100 years)
    final stability = (card.stability ?? 0.0);
    final clampedStability = stability.isFinite
        ? stability.clamp(0.0, 36500.0)
        : 0.0;

    // Calculate mastery level based on stability
    var masteryLevel = _stabilityToMasteryLevel(clampedStability);

    // Prevent mastery regression on successful reviews
    // Only allow regression if entering Relearning state (failed review)
    if (previousMasteryLevel != null && card.state != fsrs.State.relearning) {
      masteryLevel = masteryLevel < previousMasteryLevel
          ? previousMasteryLevel
          : masteryLevel;
    }

    // Convert FSRS State enum to integer for storage
    final stateInt = _stateToInt(card.state);

    return UserProgressTableCompanion(
      passageId: Value(passageId),
      masteryLevel: Value(masteryLevel),
      state: Value(stateInt),
      step: Value(card.step),
      stability: Value(clampedStability),
      difficulty: Value(card.difficulty ?? 5.0),
      lastReviewed: Value(card.lastReview),
      nextReview: Value(card.due),
    );
  }

  /// Convert a practice session performance to FSRS Rating.
  ///
  /// Maps our 0-4 performance scale to FSRS's Rating enum:
  /// - 0-1 (failed/struggled) → Rating.again
  /// - 2 (moderate difficulty) → Rating.hard
  /// - 3 (good recall) → Rating.good
  /// - 4 (easy recall) → Rating.easy
  static fsrs.Rating performanceToRating(int performance) {
    switch (performance) {
      case 0:
      case 1:
        return fsrs.Rating.again;
      case 2:
        return fsrs.Rating.hard;
      case 3:
        return fsrs.Rating.good;
      case 4:
        return fsrs.Rating.easy;
      default:
        return fsrs.Rating.good; // Default to 'good' for unexpected values
    }
  }

  /// Convert FSRS Rating back to a performance score (0-4 scale).
  ///
  /// Inverse of performanceToRating for symmetry.
  static int ratingToPerformance(fsrs.Rating rating) {
    switch (rating) {
      case fsrs.Rating.again:
        return 0;
      case fsrs.Rating.hard:
        return 2;
      case fsrs.Rating.good:
        return 3;
      case fsrs.Rating.easy:
        return 4;
    }
  }

  /// Create a new FSRS Card for a passage that has never been practiced.
  ///
  /// Returns a card in the Learning state with default FSRS parameters.
  static Future<fsrs.Card> createNewCard(String passageId) async {
    final card = await fsrs.Card.create();
    // Override cardId with our passageId hash for consistency
    return fsrs.Card(
      cardId: passageId.hashCode,
      state: card.state,
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due,
      lastReview: card.lastReview,
    );
  }

  // --- Private helper methods ---

  /// Convert FSRS State enum to integer for database storage.
  static int _stateToInt(fsrs.State state) {
    switch (state) {
      case fsrs.State.learning:
        return 0;
      case fsrs.State.review:
        return 1;
      case fsrs.State.relearning:
        return 2;
    }
  }

  /// Convert integer from database to FSRS State enum.
  static fsrs.State _intToState(int stateInt) {
    switch (stateInt) {
      case 0:
        return fsrs.State.learning;
      case 1:
        return fsrs.State.review;
      case 2:
        return fsrs.State.relearning;
      default:
        return fsrs.State.learning; // Default to learning for unexpected values
    }
  }

  /// Map FSRS stability (days) to our mastery level scale (0-4).
  ///
  /// - 0: New (Stability = 0)
  /// - 1: Acquired (Stability > 0)
  /// - 2: Solid (Stability > 3 days)
  /// - 3: Strong (Stability > 14 days)
  /// - 4: Mastered (Stability > 90 days)
  static int _stabilityToMasteryLevel(double stability) {
    if (stability <= 0) return 0; // New
    if (stability <= 3) return 1; // Acquired (0-3 days)
    if (stability <= 14) return 2; // Solid (3-14 days)
    if (stability <= 90) return 3; // Strong (14-90 days)
    return 4; // Mastered (> 90 days)
  }
}
