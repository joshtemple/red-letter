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

  /// Get passages due for review.
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

  /// Update SRS scheduling data after a review.
  ///
  /// Updates interval, repetitionCount, easeFactor, lastReviewed, and nextReview.
  /// Uses transaction to ensure atomic update of all SRS fields.
  Future<void> updateSRSData({
    required String passageId,
    required int interval,
    required int repetitionCount,
    required int easeFactor,
    required DateTime lastReviewed,
    required DateTime nextReview,
  }) async {
    await transaction(() async {
      await (update(userProgressTable)
            ..where((p) => p.passageId.equals(passageId)))
          .write(UserProgressTableCompanion(
        interval: Value(interval),
        repetitionCount: Value(repetitionCount),
        easeFactor: Value(easeFactor),
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

  /// Record a review event with updated SRS and mastery data.
  ///
  /// Combines mastery level update with SRS scheduling in a single transaction.
  Future<void> recordReview({
    required String passageId,
    required int masteryLevel,
    required int interval,
    required int repetitionCount,
    required int easeFactor,
    required DateTime lastReviewed,
    required DateTime nextReview,
  }) async {
    await transaction(() async {
      await (update(userProgressTable)
            ..where((p) => p.passageId.equals(passageId)))
          .write(UserProgressTableCompanion(
        masteryLevel: Value(masteryLevel),
        interval: Value(interval),
        repetitionCount: Value(repetitionCount),
        easeFactor: Value(easeFactor),
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
