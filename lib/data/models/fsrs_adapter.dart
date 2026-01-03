import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/database/app_database.dart';

/// Adapter that bridges Red Letter's domain model with the FSRS package.
///
/// Provides conversion between Drift's UserProgress data and FSRS Card objects,
/// enabling the use of the FSRS algorithm for spaced repetition scheduling.
///
/// **Note on Schema Evolution:**
/// The current UserProgress table uses traditional SM-2 fields (interval,
/// repetitionCount, easeFactor). FSRS uses different fields (stability,
/// difficulty, step). This adapter handles the conversion, but full migration
/// to FSRS-native storage will require schema updates in a future milestone.
class FSRSAdapter {
  /// Convert UserProgress Drift data to an FSRS Card object.
  ///
  /// Maps our domain fields to FSRS fields:
  /// - passageId → cardId (hashed to int)
  /// - masteryLevel → state (0-1: Learning, 2+: Review)
  /// - nextReview → due
  /// - lastReviewed → lastReview
  ///
  /// For FSRS-specific fields (stability, difficulty, step), we use defaults
  /// or derive approximations from SM-2 data until schema migration.
  static fsrs.Card toFSRSCard(UserProgress progress, {String? passageId}) {
    // Convert passageId string to int for FSRS cardId
    // Use hashCode as a stable int representation
    final cardId = (passageId ?? progress.passageId).hashCode;

    // Map masteryLevel to FSRS State
    // 0-1: Learning (new or still learning)
    // 2+: Review (graduated to review state)
    final state = progress.masteryLevel >= 2
        ? fsrs.State.review
        : fsrs.State.learning;

    // Determine step (null for Review state, 0 for Learning)
    final step = state == fsrs.State.review ? null : 0;

    // FSRS fields we'll need to approximate or set defaults for
    // These will be properly calculated by FSRS scheduler on first use
    // Stability: approximate from interval (FSRS uses float days, we use int)
    final stability = progress.interval.toDouble();

    // Difficulty: normalize from easeFactor (SM-2 uses 1.3-2.5, FSRS uses 0-10)
    // easeFactor is stored as int * 100 (e.g., 250 = 2.5)
    // Convert 130-250 range to roughly 0-10 range
    final easeFactor = progress.easeFactor / 100.0;
    final difficulty = ((2.5 - easeFactor) / 1.2 * 10).clamp(0.0, 10.0);

    return fsrs.Card(
      cardId: cardId,
      state: state,
      step: step,
      stability: stability,
      difficulty: difficulty,
      due: progress.nextReview ?? DateTime.now(),
      lastReview: progress.lastReviewed,
    );
  }

  /// Convert an FSRS Card back to UserProgress companion for database updates.
  ///
  /// Maps FSRS fields back to our domain:
  /// - state → masteryLevel (Learning: 1, Review: 2+)
  /// - stability → interval (rounded to days)
  /// - due → nextReview
  /// - lastReview → lastReviewed
  ///
  /// Returns a UserProgressTableCompanion for use with Drift updates.
  static UserProgressTableCompanion toUserProgressCompanion({
    required String passageId,
    required fsrs.Card card,
    int? customMasteryLevel,
  }) {
    // Map FSRS state to masteryLevel
    // This is a basic mapping; actual mastery progression logic
    // should consider performance metrics from session
    final masteryLevel = customMasteryLevel ??
        (card.state == fsrs.State.review ? 2 : 1);

    // Convert stability (float days) to interval (int days)
    final interval = (card.stability ?? 0).round();

    // For now, we maintain easeFactor for backward compatibility
    // Calculate from difficulty (FSRS 0-10 → SM-2 1.3-2.5)
    final difficulty = card.difficulty ?? 5.0;
    final easeFactor = ((2.5 - (difficulty / 10.0 * 1.2)) * 100).round();

    // Increment repetition count (simplified - actual logic should be in business layer)
    // This is just for maintaining the field during conversion
    final repetitionCount = card.state == fsrs.State.review ? 1 : 0;

    return UserProgressTableCompanion(
      passageId: Value(passageId),
      masteryLevel: Value(masteryLevel),
      interval: Value(interval),
      repetitionCount: Value(repetitionCount),
      easeFactor: Value(easeFactor),
      lastReviewed: Value(card.lastReview),
      nextReview: Value(card.due),
    );
  }

  /// Convert a practice session rating to FSRS Rating.
  ///
  /// Maps our 0-4 mastery performance scale to FSRS's 1-4 rating scale:
  /// - 0-1 (failed/struggled) → Rating.again (1)
  /// - 2 (moderate difficulty) → Rating.hard (2)
  /// - 3 (good recall) → Rating.good (3)
  /// - 4 (easy recall) → Rating.easy (4)
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
        // Default to 'good' for unexpected values
        return fsrs.Rating.good;
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
  /// Equivalent to calling `Card.create()` from the FSRS package.
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
}
