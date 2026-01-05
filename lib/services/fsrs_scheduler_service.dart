import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/models/fsrs_adapter.dart';

/// Service that wraps the FSRS scheduler for spaced repetition scheduling.
///
/// Provides a clean interface for the app to schedule passage reviews using
/// the FSRS (Free Spaced Repetition Scheduler) algorithm. Handles conversion
/// between our domain types (UserProgress) and FSRS types (Card) via FSRSAdapter.
///
/// The FSRS algorithm optimizes review intervals based on:
/// - Retrievability: Probability of recall at review time
/// - Difficulty: Inherent difficulty of the material
/// - Stability: How long the memory remains stable
class FSRSSchedulerService {
  /// The underlying FSRS scheduler instance
  final fsrs.Scheduler _scheduler;

  /// Create a scheduler with default Red Letter parameters.
  ///
  /// Default configuration:
  /// - Desired retention: 90% (balances learning efficiency with review load)
  /// - Learning steps: 1min, 10min (quick initial reinforcement)
  /// - Relearning steps: 10min (fast reacquisition for forgotten items)
  /// - Maximum interval: 365 days (yearly reviews for mastered passages)
  /// - Fuzzing enabled: Adds randomness to prevent review clustering
  FSRSSchedulerService({fsrs.Scheduler? scheduler})
    : _scheduler = scheduler ?? _createDefaultScheduler();

  /// Create the default FSRS scheduler with Red Letter's optimized parameters.
  static fsrs.Scheduler _createDefaultScheduler() {
    return fsrs.Scheduler(
      // Default FSRS v4 parameters (optimized for general learning)
      // These can be customized per-user based on their performance data
      parameters: const [
        0.4072,
        1.1829,
        3.1262,
        15.4722,
        7.2102,
        0.5316,
        1.0651,
        0.0234,
        1.616,
        0.1544,
        1.0826,
        1.9813,
        0.0953,
        0.2975,
        2.2042,
        0.2407,
        2.9466,
        0.5034,
        0.6567,
        0.1514,
        0.2,
      ],
      // Desired retention: 90% recall probability at review time
      desiredRetention: 0.9,
      // Learning steps: Empty to skip learning phase and graduate immediately
      // This is because Red Letter handles acquisition via the practice engine
      learningSteps: const [],
      // Relearning steps for forgotten passages: 10 minutes
      // Allows faster reacquisition than initial learning
      relearningSteps: const [Duration(minutes: 10)],
      // Maximum interval: 1 year
      // Even well-mastered passages should be reviewed annually
      maximumInterval: 365,
      // Enable fuzzing: adds ±2.5% randomness to intervals
      // Prevents review clustering and makes practice feel more natural
      enableFuzzing: true,
    );
  }

  /// Review a passage and calculate the next review schedule.
  ///
  /// Takes a UserProgress record and a performance rating, then returns
  /// an updated UserProgressTableCompanion with new SRS scheduling data.
  ///
  /// The rating should come from the practice session performance:
  /// - Rating.again (1): Failed to recall, needs relearning
  /// - Rating.hard (2): Recalled with significant difficulty
  /// - Rating.good (3): Recalled after brief hesitation
  /// - Rating.easy (4): Recalled effortlessly
  ///
  /// Returns a companion that can be used to update the database via
  /// UserProgressDAO.
  UserProgressTableCompanion reviewPassage({
    required String passageId,
    required UserProgress progress,
    required fsrs.Rating rating,
  }) {
    // Convert UserProgress to FSRS Card
    final currentCard = FSRSAdapter.toFSRSCard(progress, passageId: passageId);

    // Use FSRS scheduler to calculate new card state
    final result = _scheduler.reviewCard(currentCard, rating);
    final updatedCard = result.card;

    // Convert back to UserProgress companion
    return FSRSAdapter.toUserProgressCompanion(
      passageId: passageId,
      card: updatedCard,
    );
  }

  /// Calculate when a passage should next be reviewed.
  ///
  /// Simulates a review with the given rating and returns the due date
  /// without actually updating any data. Useful for preview/what-if scenarios.
  DateTime calculateNextReview({
    required UserProgress progress,
    required String passageId,
    required fsrs.Rating rating,
  }) {
    final currentCard = FSRSAdapter.toFSRSCard(progress, passageId: passageId);
    final result = _scheduler.reviewCard(currentCard, rating);
    return result.card.due;
  }

  /// Get the current retrievability of a passage.
  ///
  /// Retrievability is the estimated probability (0.0 to 1.0) that the user
  /// can recall the passage at the current moment. This decreases over time
  /// since the last review based on the stability parameter.
  ///
  /// Returns null if the passage has never been reviewed.
  double? getRetrievability({
    required UserProgress progress,
    required String passageId,
  }) {
    if (progress.lastReviewed == null) return null;

    final card = FSRSAdapter.toFSRSCard(progress, passageId: passageId);
    return _scheduler.getCardRetrievability(card);
  }

  /// Get all possible next review dates for different ratings.
  ///
  /// Returns a map of Rating → DateTime showing when the passage would be
  /// due if reviewed with each possible rating. Useful for UI previews.
  Map<fsrs.Rating, DateTime> previewNextReviewDates({
    required UserProgress progress,
    required String passageId,
  }) {
    final currentCard = FSRSAdapter.toFSRSCard(progress, passageId: passageId);

    return {
      for (final rating in fsrs.Rating.values)
        rating: _scheduler.reviewCard(currentCard, rating).card.due,
    };
  }

  /// Create a new FSRS card for a passage that has never been practiced.
  ///
  /// Returns a UserProgressTableCompanion that can be used to create
  /// the initial progress entry with FSRS defaults.
  Future<UserProgressTableCompanion> createInitialProgress(
    String passageId,
  ) async {
    final newCard = await FSRSAdapter.createNewCard(passageId);
    return FSRSAdapter.toUserProgressCompanion(
      passageId: passageId,
      card: newCard,
    );
  }

  /// Get the underlying FSRS scheduler for advanced use cases.
  ///
  /// Generally should not be needed - prefer using the service methods.
  /// Exposed for testing and advanced integrations.
  fsrs.Scheduler get scheduler => _scheduler;
}
