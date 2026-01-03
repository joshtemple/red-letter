import 'package:drift/drift.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/tables.dart';

part 'user_progress_dao.g.dart';

/// Data Access Object for user progress tracking and SRS operations.
///
/// Handles mastery level updates, SRS scheduling data, and review queue queries.
/// All updates use transactions to ensure atomic state changes.
@DriftAccessor(tables: [UserProgressTable])
class UserProgressDAO extends DatabaseAccessor<AppDatabase>
    with _$UserProgressDAOMixin {
  UserProgressDAO(super.db);

  // ========== Query Methods ==========

  /// Get progress for a specific passage.
  ///
  /// Returns null if user has no progress for this passage yet.
  Future<UserProgress?> getProgressByPassageId(String passageId) {
    return (select(userProgressTable)
          ..where((p) => p.passageId.equals(passageId)))
        .getSingleOrNull();
  }

  /// Get all user progress entries.
  ///
  /// Useful for syncing or statistics.
  Future<List<UserProgress>> getAllProgress() {
    return select(userProgressTable).get();
  }

  /// Get passages due for review (all states).
  ///
  /// Returns progress entries where nextReview is null or in the past.
  /// Ordered by nextReview (oldest first) for SRS queue priority.
  Future<List<UserProgress>> getDueForReview() {
    final now = DateTime.now();
    return (select(userProgressTable)
          ..where((p) => p.nextReview.isNull() | p.nextReview.isSmallerThanValue(now))
          ..orderBy([(p) => OrderingTerm.asc(p.nextReview)]))
        .get();
  }

  /// Get new cards (never reviewed or in initial learning state).
  ///
  /// Returns cards with state=0 (learning) and step=null/0.
  /// These are candidates for initial acquisition sessions.
  /// Ordered by passage ID for deterministic ordering.
  ///
  /// Use [limit] to control working set size (e.g., 5 new cards per day).
  Future<List<UserProgress>> getNewCards({int? limit}) {
    final query = select(userProgressTable)
      ..where((p) =>
          p.state.equals(0) & // Learning state
          (p.step.isNull() | p.step.equals(0)) & // Initial step
          p.lastReviewed.isNull()) // Never reviewed
      ..orderBy([(p) => OrderingTerm.asc(p.passageId)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Get cards due for review (review state only).
  ///
  /// Returns cards in review state (1) where nextReview is in the past.
  /// Ordered by nextReview ascending (most overdue first) for optimal retention.
  ///
  /// Use [limit] to cap daily review load.
  Future<List<UserProgress>> getDueReviewCards({int? limit}) {
    final now = DateTime.now();
    final query = select(userProgressTable)
      ..where((p) =>
          p.state.equals(1) & // Review state
          p.nextReview.isSmallerThanValue(now))
      ..orderBy([(p) => OrderingTerm.asc(p.nextReview)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Get cards in learning state with upcoming or due reviews.
  ///
  /// Returns cards in learning state (0) that have been reviewed at least once.
  /// These are cards progressing through initial learning steps.
  /// Ordered by nextReview (soonest first).
  Future<List<UserProgress>> getLearningCards() {
    final now = DateTime.now();
    return (select(userProgressTable)
          ..where((p) =>
              p.state.equals(0) & // Learning state
              p.lastReviewed.isNotNull() & // Has been reviewed
              (p.nextReview.isNull() | p.nextReview.isSmallerThanValue(now)))
          ..orderBy([(p) => OrderingTerm.asc(p.nextReview)]))
        .get();
  }

  /// Get cards in relearning state (failed reviews).
  ///
  /// Returns cards in relearning state (2) where nextReview is due or null.
  /// These are priority cards that need immediate attention.
  /// Ordered by nextReview (most urgent first).
  Future<List<UserProgress>> getRelearningCards() {
    final now = DateTime.now();
    return (select(userProgressTable)
          ..where((p) =>
              p.state.equals(2) & // Relearning state
              (p.nextReview.isNull() | p.nextReview.isSmallerThanValue(now)))
          ..orderBy([(p) => OrderingTerm.asc(p.nextReview)]))
        .get();
  }

  /// Get combined review queue (relearning + review + learning).
  ///
  /// Returns all due cards across all states, prioritized by urgency:
  /// 1. Relearning cards (failed reviews - highest priority)
  /// 2. Review cards (graduated cards)
  /// 3. Learning cards (in acquisition)
  ///
  /// Use [limit] to cap total queue size.
  Future<List<UserProgress>> getReviewQueue({int? limit}) async {
    final now = DateTime.now();

    // Get all due cards with state-based priority ordering
    final query = select(userProgressTable)
      ..where((p) =>
          (p.nextReview.isNull() | p.nextReview.isSmallerThanValue(now)) &
          p.lastReviewed.isNotNull()) // Exclude brand new cards
      ..orderBy([
        // Priority: relearning (2) > review (1) > learning (0)
        (p) => OrderingTerm.desc(p.state),
        // Within same state, oldest due first
        (p) => OrderingTerm.asc(p.nextReview),
      ]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Get count of cards by FSRS state.
  ///
  /// Returns map of state -> count:
  /// - 0: Learning
  /// - 1: Review
  /// - 2: Relearning
  Future<Map<int, int>> getCardCountsByState() async {
    final query = selectOnly(userProgressTable)
      ..addColumns([
        userProgressTable.state,
        userProgressTable.id.count(),
      ])
      ..groupBy([userProgressTable.state]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(userProgressTable.state)!:
            row.read(userProgressTable.id.count())!
    };
  }

  /// Get passages by mastery level.
  ///
  /// Useful for filtering practice queue by difficulty.
  Future<List<UserProgress>> getProgressByMasteryLevel(int masteryLevel) {
    return (select(userProgressTable)
          ..where((p) => p.masteryLevel.equals(masteryLevel)))
        .get();
  }

  /// Get count of passages at each mastery level.
  ///
  /// Returns a map of masteryLevel -> count for statistics.
  Future<Map<int, int>> getMasteryLevelCounts() async {
    final query = selectOnly(userProgressTable)
      ..addColumns([
        userProgressTable.masteryLevel,
        userProgressTable.id.count(),
      ])
      ..groupBy([userProgressTable.masteryLevel]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(userProgressTable.masteryLevel)!:
            row.read(userProgressTable.id.count())!
    };
  }

  // ========== Insert/Upsert Methods ==========

  /// Create initial progress entry for a passage.
  ///
  /// Sets default values: masteryLevel=0, interval=0, repetitions=0, ease=2.5
  Future<int> createProgress(String passageId) {
    return into(userProgressTable).insert(
      UserProgressTableCompanion.insert(
        passageId: passageId,
      ),
    );
  }

  /// Upsert progress entry.
  ///
  /// If progress exists (same passageId), updates it. Otherwise creates new entry.
  Future<void> upsertProgress(UserProgressTableCompanion progress) async {
    await into(userProgressTable).insert(
      progress,
      mode: InsertMode.insertOrReplace,
    );
  }

  // ========== Update Methods ==========

  /// Update mastery level for a passage.
  ///
  /// Mastery levels: 0=new, 1=learning, 2=familiar, 3=mastered, 4=locked-in
  Future<int> updateMasteryLevel(String passageId, int masteryLevel) {
    return (update(userProgressTable)
          ..where((p) => p.passageId.equals(passageId)))
        .write(UserProgressTableCompanion(
      masteryLevel: Value(masteryLevel),
    ));
  }

  /// Update FSRS scheduling data after a review.
  ///
  /// Updates stability, difficulty, step, state, lastReviewed, and nextReview.
  /// Uses transaction to ensure atomic update of all FSRS fields.
  ///
  /// Note: Prefer using FSRSSchedulerService.reviewPassage() which returns
  /// a companion that can be passed to upsertProgress().
  Future<void> updateFSRSData({
    required String passageId,
    required double stability,
    required double difficulty,
    required int? step,
    required int state,
    required DateTime lastReviewed,
    required DateTime? nextReview,
  }) async {
    await transaction(() async {
      await (update(userProgressTable)
            ..where((p) => p.passageId.equals(passageId)))
          .write(UserProgressTableCompanion(
        stability: Value(stability),
        difficulty: Value(difficulty),
        step: Value(step),
        state: Value(state),
        lastReviewed: Value(lastReviewed),
        nextReview: Value(nextReview),
      ));
    });
  }

  /// Update semantic reflection text.
  ///
  /// Stores the user's reflection to enforce understanding before rote practice.
  Future<int> updateSemanticReflection(
      String passageId, String reflection) {
    return (update(userProgressTable)
          ..where((p) => p.passageId.equals(passageId)))
        .write(UserProgressTableCompanion(
      semanticReflection: Value(reflection),
    ));
  }

  /// Record a review event with updated FSRS and mastery data.
  ///
  /// Combines mastery level update with FSRS scheduling in a single transaction.
  ///
  /// Note: Prefer using FSRSSchedulerService.reviewPassage() which returns
  /// a companion that can be passed to upsertProgress() directly.
  Future<void> recordReview({
    required String passageId,
    required int masteryLevel,
    required double stability,
    required double difficulty,
    required int? step,
    required int state,
    required DateTime lastReviewed,
    required DateTime? nextReview,
  }) async {
    await transaction(() async {
      await (update(userProgressTable)
            ..where((p) => p.passageId.equals(passageId)))
          .write(UserProgressTableCompanion(
        masteryLevel: Value(masteryLevel),
        stability: Value(stability),
        difficulty: Value(difficulty),
        step: Value(step),
        state: Value(state),
        lastReviewed: Value(lastReviewed),
        nextReview: Value(nextReview),
      ));
    });
  }

  /// Update last sync timestamp.
  ///
  /// Used for cloud sync tracking.
  Future<int> updateLastSync(String passageId, DateTime syncTime) {
    return (update(userProgressTable)
          ..where((p) => p.passageId.equals(passageId)))
        .write(UserProgressTableCompanion(
      lastSync: Value(syncTime),
    ));
  }

  // ========== Delete Methods ==========

  /// Delete progress for a specific passage.
  ///
  /// Note: Progress will auto-delete if the passage is deleted (CASCADE).
  Future<int> deleteProgress(String passageId) {
    return (delete(userProgressTable)
          ..where((p) => p.passageId.equals(passageId)))
        .go();
  }

  /// Delete all user progress.
  ///
  /// WARNING: This removes all progress data! Only use for account deletion.
  Future<int> deleteAllProgress() {
    return delete(userProgressTable).go();
  }
}
