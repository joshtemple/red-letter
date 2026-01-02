import 'package:drift/drift.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/tables.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';

part 'passage_dao.g.dart';

/// Data Access Object for static passage operations.
///
/// Optimized for read-heavy workload with efficient batch inserts
/// and indexed queries by ID, translation, and tags.
/// Includes client-side join queries to decorate passages with user progress.
@DriftAccessor(tables: [Passages, UserProgressTable])
class PassageDAO extends DatabaseAccessor<AppDatabase> with _$PassageDAOMixin {
  PassageDAO(super.db);

  // ========== Query Methods ==========

  /// Get a single passage by its ID.
  ///
  /// Returns null if no passage with the given ID exists.
  Future<Passage?> getPassageById(String passageId) {
    return (select(
      passages,
    )..where((p) => p.passageId.equals(passageId))).getSingleOrNull();
  }

  /// Get all passages for a specific translation.
  ///
  /// Uses index on translationId for performance.
  Future<List<Passage>> getPassagesByTranslation(String translationId) {
    return (select(passages)
          ..where((p) => p.translationId.equals(translationId))
          ..orderBy([(p) => OrderingTerm.asc(p.passageId)]))
        .get();
  }

  /// Get passages that contain a specific tag.
  ///
  /// Tags are comma-separated, so this uses a LIKE query.
  /// Example: tag="commands" matches "sermon-on-mount,commands"
  Future<List<Passage>> getPassagesByTag(String tag) {
    return (select(passages)
          ..where((p) => p.tags.like('%$tag%'))
          ..orderBy([(p) => OrderingTerm.asc(p.passageId)]))
        .get();
  }

  /// Get all passages.
  ///
  /// Ordered by passageId for consistent listing.
  Future<List<Passage>> getAllPassages() {
    return (select(
      passages,
    )..orderBy([(p) => OrderingTerm.asc(p.passageId)])).get();
  }

  /// Get count of passages for a translation.
  ///
  /// Useful for statistics without loading all data.
  Future<int> getPassageCountByTranslation(String translationId) async {
    final count = passages.passageId.count();
    final query = selectOnly(passages)
      ..addColumns([count])
      ..where(passages.translationId.equals(translationId));

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ========== Client-Side Join Methods ==========

  /// Get a passage decorated with user progress.
  ///
  /// Performs client-side join between static passage and user progress.
  /// Returns null if the passage doesn't exist.
  /// Progress will be null if the user hasn't started this passage yet.
  Future<PassageWithProgress?> getPassageWithProgressById(
    String passageId,
  ) async {
    final query = select(passages).join([
      leftOuterJoin(
        userProgressTable,
        userProgressTable.passageId.equalsExp(passages.passageId),
      ),
    ])..where(passages.passageId.equals(passageId));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return PassageWithProgress(
      passage: result.readTable(passages),
      progress: result.readTableOrNull(userProgressTable),
    );
  }

  /// Get all passages decorated with user progress.
  ///
  /// Performs client-side join for all passages. Ordered by passageId.
  /// Passages without progress will have null progress field.
  Future<List<PassageWithProgress>> getAllPassagesWithProgress() async {
    final query = select(passages).join([
      leftOuterJoin(
        userProgressTable,
        userProgressTable.passageId.equalsExp(passages.passageId),
      ),
    ])..orderBy([OrderingTerm.asc(passages.passageId)]);

    final results = await query.get();
    return results.map((row) {
      return PassageWithProgress(
        passage: row.readTable(passages),
        progress: row.readTableOrNull(userProgressTable),
      );
    }).toList();
  }

  /// Get passages with progress for a specific translation.
  ///
  /// Performs client-side join filtered by translation.
  /// Useful for building "The Living List" UI for a specific Bible version.
  Future<List<PassageWithProgress>> getPassagesWithProgressByTranslation(
    String translationId,
  ) async {
    final query =
        select(passages).join([
            leftOuterJoin(
              userProgressTable,
              userProgressTable.passageId.equalsExp(passages.passageId),
            ),
          ])
          ..where(passages.translationId.equals(translationId))
          ..orderBy([OrderingTerm.asc(passages.passageId)]);

    final results = await query.get();
    return results.map((row) {
      return PassageWithProgress(
        passage: row.readTable(passages),
        progress: row.readTableOrNull(userProgressTable),
      );
    }).toList();
  }

  /// Get passages with progress filtered by mastery level.
  ///
  /// Returns only passages that have progress at the specified mastery level.
  /// Note: This excludes passages with no progress (use getAllPassagesWithProgress
  /// and filter client-side if you need masteryLevel=0 including unpracticed).
  Future<List<PassageWithProgress>> getPassagesWithProgressByMasteryLevel(
    int masteryLevel,
  ) async {
    final query =
        select(passages).join([
            innerJoin(
              userProgressTable,
              userProgressTable.passageId.equalsExp(passages.passageId),
            ),
          ])
          ..where(userProgressTable.masteryLevel.equals(masteryLevel))
          ..orderBy([OrderingTerm.asc(passages.passageId)]);

    final results = await query.get();
    return results.map((row) {
      return PassageWithProgress(
        passage: row.readTable(passages),
        progress: row.readTable(userProgressTable),
      );
    }).toList();
  }

  // ========== Reactive Watch Methods ==========

  /// Watch a single passage with progress.
  ///
  /// Emits a new value whenever the passage or its progress changes.
  Stream<PassageWithProgress?> watchPassageWithProgressById(String passageId) {
    final query = select(passages).join([
      leftOuterJoin(
        userProgressTable,
        userProgressTable.passageId.equalsExp(passages.passageId),
      ),
    ])..where(passages.passageId.equals(passageId));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return PassageWithProgress(
        passage: row.readTable(passages),
        progress: row.readTableOrNull(userProgressTable),
      );
    });
  }

  /// Watch all passages with progress.
  ///
  /// Emits a new list whenever any passage or progress changes.
  Stream<List<PassageWithProgress>> watchAllPassagesWithProgress() {
    final query = select(passages).join([
      leftOuterJoin(
        userProgressTable,
        userProgressTable.passageId.equalsExp(passages.passageId),
      ),
    ])..orderBy([OrderingTerm.asc(passages.passageId)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PassageWithProgress(
          passage: row.readTable(passages),
          progress: row.readTableOrNull(userProgressTable),
        );
      }).toList();
    });
  }

  /// Watch passages with progress for a specific translation.
  ///
  /// Emits a new list whenever relevant data changes.
  Stream<List<PassageWithProgress>> watchPassagesWithProgressByTranslation(
    String translationId,
  ) {
    final query =
        select(passages).join([
            leftOuterJoin(
              userProgressTable,
              userProgressTable.passageId.equalsExp(passages.passageId),
            ),
          ])
          ..where(passages.translationId.equals(translationId))
          ..orderBy([OrderingTerm.asc(passages.passageId)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PassageWithProgress(
          passage: row.readTable(passages),
          progress: row.readTableOrNull(userProgressTable),
        );
      }).toList();
    });
  }

  // ========== Insert Methods ==========

  /// Insert a single passage.
  ///
  /// Returns the passageId of the inserted row.
  /// If a passage with the same ID exists, this will fail.
  Future<String> insertPassage(PassagesCompanion passage) async {
    await into(passages).insert(passage);
    return passage.passageId.value;
  }

  /// Insert multiple passages in a single transaction.
  ///
  /// Much more efficient than individual inserts for seeding data.
  /// Returns the number of passages inserted.
  Future<int> insertPassageBatch(List<PassagesCompanion> passageList) async {
    return await transaction(() async {
      int count = 0;
      for (final passage in passageList) {
        await into(passages).insert(passage);
        count++;
      }
      return count;
    });
  }

  /// Upsert (insert or replace) a single passage.
  ///
  /// If a passage with the same ID exists, it will be replaced.
  Future<void> upsertPassage(PassagesCompanion passage) async {
    await into(passages).insertOnConflictUpdate(passage);
  }

  /// Upsert multiple passages in a batch.
  ///
  /// Useful for updating an existing translation or adding new passages.
  Future<int> upsertPassageBatch(List<PassagesCompanion> passageList) async {
    return await transaction(() async {
      int count = 0;
      for (final passage in passageList) {
        await into(passages).insertOnConflictUpdate(passage);
        count++;
      }
      return count;
    });
  }

  // ========== Delete Methods ==========

  /// Delete a passage by ID.
  ///
  /// Note: This will cascade delete associated UserProgress entries.
  Future<int> deletePassageById(String passageId) {
    return (delete(passages)..where((p) => p.passageId.equals(passageId))).go();
  }

  /// Delete all passages for a specific translation.
  ///
  /// Use with caution - this will cascade delete all user progress.
  Future<int> deletePassagesByTranslation(String translationId) {
    return (delete(
      passages,
    )..where((p) => p.translationId.equals(translationId))).go();
  }

  /// Delete all passages.
  ///
  /// WARNING: This will cascade delete ALL user progress!
  /// Only use for testing or complete database reset.
  Future<int> deleteAllPassages() {
    return delete(passages).go();
  }
}
