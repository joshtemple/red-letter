import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/passage_dao.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';

void main() {
  late AppDatabase database;
  late PassageDAO passageDAO;
  late UserProgressDAO progressDAO;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    passageDAO = PassageDAO(database);
    progressDAO = UserProgressDAO(database);
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper to insert a test passage
  Future<void> insertTestPassage(String passageId) async {
    await passageDAO.insertPassage(
      PassagesCompanion.insert(
        passageId: passageId,
        translationId: 'niv',
        reference: 'Test $passageId',
        passageText: 'Test passage text',
        book: 'TestBook',
        chapter: 1,
        startVerse: 1,
        endVerse: 1,
      ),
    );
  }

  group('UserProgressDAO - Query Operations', () {
    test('getProgressByPassageId returns progress when it exists', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final progress = await progressDAO.getProgressByPassageId('test-1');

      expect(progress, isNotNull);
      expect(progress!.passageId, equals('test-1'));
      expect(progress.masteryLevel, equals(0)); // Default
    });

    test('getProgressByPassageId returns null when no progress exists',
        () async {
      final progress = await progressDAO.getProgressByPassageId('non-existent');
      expect(progress, isNull);
    });

    test('getAllProgress returns all progress entries', () async {
      await insertTestPassage('test-1');
      await insertTestPassage('test-2');
      await insertTestPassage('test-3');

      await progressDAO.createProgress('test-1');
      await progressDAO.createProgress('test-2');
      await progressDAO.createProgress('test-3');

      final all = await progressDAO.getAllProgress();
      expect(all, hasLength(3));
    });

    test('getDueForReview returns passages with null nextReview', () async {
      await insertTestPassage('test-1');
      await insertTestPassage('test-2');

      await progressDAO.createProgress('test-1');
      await progressDAO.createProgress('test-2');

      final due = await progressDAO.getDueForReview();
      expect(due, hasLength(2)); // Both have null nextReview
    });

    test('getDueForReview returns passages with past nextReview', () async {
      await insertTestPassage('test-1');
      await insertTestPassage('test-2');
      await insertTestPassage('test-3');

      await progressDAO.createProgress('test-1');
      await progressDAO.createProgress('test-2');
      await progressDAO.createProgress('test-3');

      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 1));
      final future = now.add(const Duration(days: 1));

      // Update nextReview times
      await progressDAO.updateFSRSData(
        passageId: 'test-1',
        stability: 1.0,
        difficulty: 5.0,
        step: null,
        state: 1, // Review state
        lastReviewed: past,
        nextReview: past, // Due in the past
      );

      await progressDAO.updateFSRSData(
        passageId: 'test-2',
        stability: 1.0,
        difficulty: 5.0,
        step: null,
        state: 1, // Review state
        lastReviewed: now,
        nextReview: future, // Not due yet
      );

      final due = await progressDAO.getDueForReview();
      expect(due, hasLength(2)); // test-1 (past) and test-3 (null)
      expect(due.any((p) => p.passageId == 'test-1'), isTrue);
      expect(due.any((p) => p.passageId == 'test-3'), isTrue);
    });

    test('getProgressByMasteryLevel filters by mastery level', () async {
      await insertTestPassage('test-1');
      await insertTestPassage('test-2');
      await insertTestPassage('test-3');

      await progressDAO.createProgress('test-1');
      await progressDAO.createProgress('test-2');
      await progressDAO.createProgress('test-3');

      await progressDAO.updateMasteryLevel('test-1', 2);
      await progressDAO.updateMasteryLevel('test-2', 2);
      await progressDAO.updateMasteryLevel('test-3', 3);

      final level2 = await progressDAO.getProgressByMasteryLevel(2);
      expect(level2, hasLength(2));
      expect(level2.every((p) => p.masteryLevel == 2), isTrue);
    });

    test('getMasteryLevelCounts returns count map', () async {
      await insertTestPassage('test-1');
      await insertTestPassage('test-2');
      await insertTestPassage('test-3');
      await insertTestPassage('test-4');

      await progressDAO.createProgress('test-1');
      await progressDAO.createProgress('test-2');
      await progressDAO.createProgress('test-3');
      await progressDAO.createProgress('test-4');

      await progressDAO.updateMasteryLevel('test-1', 0);
      await progressDAO.updateMasteryLevel('test-2', 0);
      await progressDAO.updateMasteryLevel('test-3', 2);
      await progressDAO.updateMasteryLevel('test-4', 3);

      final counts = await progressDAO.getMasteryLevelCounts();
      expect(counts[0], equals(2));
      expect(counts[2], equals(1));
      expect(counts[3], equals(1));
    });
  });

  group('UserProgressDAO - Insert/Upsert Operations', () {
    test('createProgress creates entry with default values', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final progress = await progressDAO.getProgressByPassageId('test-1');

      expect(progress, isNotNull);
      expect(progress!.masteryLevel, equals(0));
      expect(progress.stability, equals(0.0));
      expect(progress.difficulty, equals(5.0));
      expect(progress.state, equals(0)); // Learning state
    });

    test('upsertProgress creates new progress entry', () async {
      await insertTestPassage('test-1');

      await progressDAO.upsertProgress(
        UserProgressTableCompanion.insert(
          passageId: 'test-1',
          masteryLevel: const Value(1),
        ),
      );

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress, isNotNull);
      expect(progress!.masteryLevel, equals(1));
    });

    test('upsertProgress updates existing progress entry', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      // Upsert with updated mastery level
      await progressDAO.upsertProgress(
        UserProgressTableCompanion.insert(
          passageId: 'test-1',
          masteryLevel: const Value(3),
        ),
      );

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress!.masteryLevel, equals(3));

      // Verify only one entry exists
      final all = await progressDAO.getAllProgress();
      expect(all, hasLength(1));
    });
  });

  group('UserProgressDAO - Update Operations', () {
    test('updateMasteryLevel updates the mastery level', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      await progressDAO.updateMasteryLevel('test-1', 4);

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress!.masteryLevel, equals(4));
    });

    test('updateFSRSData updates all FSRS fields atomically', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final lastReviewed = DateTime.now();
      final nextReview = lastReviewed.add(const Duration(days: 3));

      await progressDAO.updateFSRSData(
        passageId: 'test-1',
        stability: 3.5,
        difficulty: 6.2,
        step: null,
        state: 1, // Review state
        lastReviewed: lastReviewed,
        nextReview: nextReview,
      );

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress!.stability, equals(3.5));
      expect(progress.difficulty, equals(6.2));
      expect(progress.step, isNull);
      expect(progress.state, equals(1));
      expect(progress.lastReviewed, isNotNull);
      expect(progress.nextReview, isNotNull);
    });

    test('updateSemanticReflection stores reflection text', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      await progressDAO.updateSemanticReflection(
        'test-1',
        'This passage teaches about love and forgiveness',
      );

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(
        progress!.semanticReflection,
        equals('This passage teaches about love and forgiveness'),
      );
    });

    test('recordReview updates both mastery and FSRS data', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final lastReviewed = DateTime.now();
      final nextReview = lastReviewed.add(const Duration(days: 5));

      await progressDAO.recordReview(
        passageId: 'test-1',
        masteryLevel: 2,
        stability: 5.8,
        difficulty: 4.5,
        step: null,
        state: 1, // Review state
        lastReviewed: lastReviewed,
        nextReview: nextReview,
      );

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress!.masteryLevel, equals(2));
      expect(progress.stability, equals(5.8));
      expect(progress.difficulty, equals(4.5));
      expect(progress.state, equals(1));
    });

    test('updateLastSync updates sync timestamp', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final syncTime = DateTime.now();
      await progressDAO.updateLastSync('test-1', syncTime);

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress!.lastSync, isNotNull);
    });
  });

  group('UserProgressDAO - Delete Operations', () {
    test('deleteProgress removes progress entry', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final deleteCount = await progressDAO.deleteProgress('test-1');
      expect(deleteCount, equals(1));

      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress, isNull);
    });

    test('deleteAllProgress removes all progress', () async {
      await insertTestPassage('test-1');
      await insertTestPassage('test-2');
      await insertTestPassage('test-3');

      await progressDAO.createProgress('test-1');
      await progressDAO.createProgress('test-2');
      await progressDAO.createProgress('test-3');

      final deleteCount = await progressDAO.deleteAllProgress();
      expect(deleteCount, equals(3));

      final all = await progressDAO.getAllProgress();
      expect(all, isEmpty);
    });

    test('progress cascades delete when passage is deleted', () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      // Delete the passage
      await passageDAO.deletePassageById('test-1');

      // Progress should also be deleted due to CASCADE
      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress, isNull);
    });
  });
}
