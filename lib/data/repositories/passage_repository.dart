import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/passage_dao.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';

/// Repository for passage and user progress operations.
///
/// Provides a clean, unified interface to the UI layer by abstracting
/// Drift implementation details. Combines PassageDAO and UserProgressDAO
/// operations into semantic business logic methods.
///
/// Benefits:
/// - Simplifies UI code by hiding database complexity
/// - Makes it easier to swap data sources (e.g., add remote sync)
/// - Improves testability with clear boundaries
/// - Centralizes business logic related to passages and progress
class PassageRepository {
  final PassageDAO _passageDAO;
  final UserProgressDAO _progressDAO;

  PassageRepository({
    required PassageDAO passageDAO,
    required UserProgressDAO progressDAO,
  }) : _passageDAO = passageDAO,
       _progressDAO = progressDAO;

  PassageDAO get passageDAO => _passageDAO;
  UserProgressDAO get progressDAO => _progressDAO;

  /// Convenience factory that creates a repository from a database instance.
  ///
  /// This is the typical way to instantiate the repository in production code.
  factory PassageRepository.fromDatabase(AppDatabase database) {
    return PassageRepository(
      passageDAO: PassageDAO(database),
      progressDAO: UserProgressDAO(database),
    );
  }

  // ========== Passage Query Methods ==========

  /// Get a single passage without progress data.
  ///
  /// Returns null if the passage doesn't exist.
  /// Use [getPassageWithProgress] if you need user progress data.
  Future<Passage?> getPassage(String passageId) {
    return _passageDAO.getPassageById(passageId);
  }

  /// Get all passages for a translation without progress data.
  ///
  /// Use [getPassagesWithProgress] if you need user progress data.
  Future<List<Passage>> getPassagesByTranslation(String translationId) {
    return _passageDAO.getPassagesByTranslation(translationId);
  }

  /// Get passages containing a specific tag.
  Future<List<Passage>> getPassagesByTag(String tag) {
    return _passageDAO.getPassagesByTag(tag);
  }

  // ========== Passage with Progress Methods ==========

  /// Get a passage decorated with user progress.
  ///
  /// Returns null if the passage doesn't exist.
  /// Progress will be null if the user hasn't started this passage yet.
  Future<PassageWithProgress?> getPassageWithProgress(String passageId) {
    return _passageDAO.getPassageWithProgressById(passageId);
  }

  /// Get all passages decorated with user progress.
  ///
  /// This is the primary method for "The Living List" UI.
  /// Passages without progress will have null progress field.
  Future<List<PassageWithProgress>> getAllPassagesWithProgress() {
    return _passageDAO.getAllPassagesWithProgress();
  }

  /// Get passages with progress for a specific translation.
  ///
  /// Ideal for building "The Living List" filtered to a Bible version.
  Future<List<PassageWithProgress>> getPassagesWithProgressByTranslation(
    String translationId,
  ) {
    return _passageDAO.getPassagesWithProgressByTranslation(translationId);
  }

  /// Get passages with progress at a specific mastery level.
  ///
  /// Only returns passages that have progress. Useful for practice queue filtering.
  Future<List<PassageWithProgress>> getPassagesWithProgressByMasteryLevel(
    int masteryLevel,
  ) {
    return _passageDAO.getPassagesWithProgressByMasteryLevel(masteryLevel);
  }

  // ========== Reactive Stream Methods ==========

  /// Watch a single passage decorated with user progress.
  ///
  /// Emits a new value whenever the passage or its progress changes.
  Stream<PassageWithProgress?> watchPassageWithProgress(String passageId) {
    return _passageDAO.watchPassageWithProgressById(passageId);
  }

  /// Watch all passages decorated with user progress.
  ///
  /// This is the primary stream for "The Living List" UI.
  Stream<List<PassageWithProgress>> watchAllPassagesWithProgress() {
    return _passageDAO.watchAllPassagesWithProgress();
  }

  /// Watch passages with progress for a specific translation.
  ///
  /// Ideal for building a reactive "Living List" filtered to a Bible version.
  Stream<List<PassageWithProgress>> watchPassagesWithProgressByTranslation(
    String translationId,
  ) {
    return _passageDAO.watchPassagesWithProgressByTranslation(translationId);
  }

  // ========== Progress Query Methods ==========

  /// Get user progress for a specific passage.
  ///
  /// Returns null if no progress exists yet.
  /// Consider using [getPassageWithProgress] if you also need passage text.
  Future<UserProgress?> getProgress(String passageId) {
    return _progressDAO.getProgressByPassageId(passageId);
  }

  /// Get all passages that are due for review.
  ///
  /// Returns progress entries where nextReview is null or in the past.
  /// Ordered by nextReview (oldest first) for SRS queue priority.
  Future<List<UserProgress>> getDueForReview() {
    return _progressDAO.getDueForReview();
  }

  /// Get count of passages at each mastery level.
  ///
  /// Returns a map of masteryLevel -> count for statistics display.
  Future<Map<int, int>> getMasteryLevelCounts() {
    return _progressDAO.getMasteryLevelCounts();
  }

  // ========== Progress Mutation Methods ==========

  /// Create initial progress for a passage.
  ///
  /// Sets default values: masteryLevel=0, interval=0, repetitions=0, ease=2.5
  /// Should be called when user first attempts a passage.
  Future<int> createProgress(String passageId) {
    return _progressDAO.createProgress(passageId);
  }

  /// Update mastery level for a passage.
  ///
  /// Mastery levels: 0=new, 1=learning, 2=familiar, 3=mastered, 4=locked-in
  Future<int> updateMasteryLevel(String passageId, int masteryLevel) {
    return _progressDAO.updateMasteryLevel(passageId, masteryLevel);
  }

  /// Record a review event with complete FSRS and mastery data.
  ///
  /// This is the primary method for updating progress after a practice session.
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
  }) {
    return _progressDAO.recordReview(
      passageId: passageId,
      masteryLevel: masteryLevel,
      stability: stability,
      difficulty: difficulty,
      step: step,
      state: state,
      lastReviewed: lastReviewed,
      nextReview: nextReview,
    );
  }

  /// Update semantic reflection for a passage.
  ///
  /// Stores the user's reflection to enforce understanding before rote practice.
  /// This is called after the Reflection Mode in the practice engine.
  Future<int> updateSemanticReflection(String passageId, String reflection) {
    return _progressDAO.updateSemanticReflection(passageId, reflection);
  }

  // ========== Passage Mutation Methods ==========

  /// Insert a single passage.
  ///
  /// Typically used by admin tools or testing.
  /// For bulk seeding, use batch operations through the DAO directly.
  Future<String> insertPassage(PassagesCompanion passage) {
    return _passageDAO.insertPassage(passage);
  }

  /// Insert multiple passages in a batch.
  ///
  /// More efficient than individual inserts for seeding data.
  Future<int> insertPassageBatch(List<PassagesCompanion> passages) {
    return _passageDAO.insertPassageBatch(passages);
  }

  // ========== Statistics and Utility Methods ==========

  /// Get total count of passages for a translation.
  ///
  /// Useful for statistics without loading all data.
  Future<int> getPassageCount(String translationId) {
    return _passageDAO.getPassageCountByTranslation(translationId);
  }

  /// Get all user progress entries.
  ///
  /// Useful for syncing or exporting data.
  Future<List<UserProgress>> getAllProgress() {
    return _progressDAO.getAllProgress();
  }

  // ========== Danger Zone ==========

  /// Delete all user progress.
  ///
  /// WARNING: This removes all progress data! Only use for account deletion.
  /// Does not affect passages (static data remains).
  Future<int> deleteAllProgress() {
    return _progressDAO.deleteAllProgress();
  }
}
