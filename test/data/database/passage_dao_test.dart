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

  group('PassageDAO - Query Operations', () {
    test('getPassageById returns passage when it exists', () async {
      // Insert test passage
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      );

      final passage = await passageDAO.getPassageById('mat-5-44');

      expect(passage, isNotNull);
      expect(passage!.passageId, equals('mat-5-44'));
      expect(passage.reference, equals('Matthew 5:44'));
      expect(passage.passageText, equals('Love your enemies'));
    });

    test('getPassageById returns null when passage does not exist', () async {
      final passage = await passageDAO.getPassageById('non-existent');
      expect(passage, isNull);
    });

    test('getPassagesByTranslation returns all passages for translation', () async {
      // Insert passages with different translations
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
        PassagesCompanion.insert(
          passageId: 'mat-6-9',
          translationId: 'niv',
          reference: 'Matthew 6:9',
          passageText: 'Our Father in heaven',
        ),
        PassagesCompanion.insert(
          passageId: 'mat-5-44-esv',
          translationId: 'esv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      ]);

      final nivPassages = await passageDAO.getPassagesByTranslation('niv');

      expect(nivPassages, hasLength(2));
      expect(nivPassages.every((p) => p.translationId == 'niv'), isTrue);
    });

    test('getPassagesByTag returns passages containing tag', () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
          tags: const Value('sermon-on-mount,commands,love'),
        ),
        PassagesCompanion.insert(
          passageId: 'mat-6-9',
          translationId: 'niv',
          reference: 'Matthew 6:9',
          passageText: 'Our Father in heaven',
          tags: const Value('sermon-on-mount,prayer'),
        ),
        PassagesCompanion.insert(
          passageId: 'john-3-16',
          translationId: 'niv',
          reference: 'John 3:16',
          passageText: 'For God so loved the world',
          tags: const Value('love,gospel'),
        ),
      ]);

      final commandPassages = await passageDAO.getPassagesByTag('commands');
      expect(commandPassages, hasLength(1));
      expect(commandPassages.first.passageId, equals('mat-5-44'));

      final lovePassages = await passageDAO.getPassagesByTag('love');
      expect(lovePassages, hasLength(2));
    });

    test('getAllPassages returns all passages ordered by ID', () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'mat-6-9',
          translationId: 'niv',
          reference: 'Matthew 6:9',
          passageText: 'Our Father',
        ),
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love enemies',
        ),
      ]);

      final all = await passageDAO.getAllPassages();

      expect(all, hasLength(2));
      expect(all[0].passageId, equals('mat-5-44')); // Sorted
      expect(all[1].passageId, equals('mat-6-9'));
    });

    test('getPassageCountByTranslation returns correct count', () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Test',
        ),
        PassagesCompanion.insert(
          passageId: 'mat-6-9',
          translationId: 'niv',
          reference: 'Matthew 6:9',
          passageText: 'Test',
        ),
        PassagesCompanion.insert(
          passageId: 'mat-5-44-esv',
          translationId: 'esv',
          reference: 'Matthew 5:44',
          passageText: 'Test',
        ),
      ]);

      final nivCount = await passageDAO.getPassageCountByTranslation('niv');
      final esvCount = await passageDAO.getPassageCountByTranslation('esv');

      expect(nivCount, equals(2));
      expect(esvCount, equals(1));
    });
  });

  group('PassageDAO - Insert Operations', () {
    test('insertPassage adds single passage successfully', () async {
      final id = await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test text',
        ),
      );

      expect(id, equals('test-1'));

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage, isNotNull);
    });

    test('insertPassageBatch adds multiple passages in transaction', () async {
      final count = await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        PassagesCompanion.insert(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
        PassagesCompanion.insert(
          passageId: 'test-3',
          translationId: 'niv',
          reference: 'Test 1:3',
          passageText: 'Test 3',
        ),
      ]);

      expect(count, equals(3));

      final all = await passageDAO.getAllPassages();
      expect(all, hasLength(3));
    });

    test('upsertPassage inserts new passage', () async {
      await passageDAO.upsertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Original text',
        ),
      );

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage!.passageText, equals('Original text'));
    });

    test('upsertPassage updates existing passage', () async {
      // Insert original
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Original text',
        ),
      );

      // Upsert with new text
      await passageDAO.upsertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Updated text',
        ),
      );

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage!.passageText, equals('Updated text'));

      // Verify only one passage exists
      final all = await passageDAO.getAllPassages();
      expect(all, hasLength(1));
    });

    test('upsertPassageBatch handles mixed insert and update', () async {
      // Insert initial passage
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Original',
        ),
      );

      // Upsert batch with one update and one new insert
      await passageDAO.upsertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Updated',
        ),
        PassagesCompanion.insert(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'New',
        ),
      ]);

      final all = await passageDAO.getAllPassages();
      expect(all, hasLength(2));

      final updated = await passageDAO.getPassageById('test-1');
      expect(updated!.passageText, equals('Updated'));
    });
  });

  group('PassageDAO - Delete Operations', () {
    test('deletePassageById removes single passage', () async {
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      final deleteCount = await passageDAO.deletePassageById('test-1');
      expect(deleteCount, equals(1));

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage, isNull);
    });

    test('deletePassagesByTranslation removes all for translation', () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'niv-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
        PassagesCompanion.insert(
          passageId: 'niv-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test',
        ),
        PassagesCompanion.insert(
          passageId: 'esv-1',
          translationId: 'esv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      ]);

      final deleteCount = await passageDAO.deletePassagesByTranslation('niv');
      expect(deleteCount, equals(2));

      final remaining = await passageDAO.getAllPassages();
      expect(remaining, hasLength(1));
      expect(remaining.first.translationId, equals('esv'));
    });

    test('deleteAllPassages removes all passages', () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
        PassagesCompanion.insert(
          passageId: 'test-2',
          translationId: 'esv',
          reference: 'Test 1:2',
          passageText: 'Test',
        ),
      ]);

      final deleteCount = await passageDAO.deleteAllPassages();
      expect(deleteCount, equals(2));

      final all = await passageDAO.getAllPassages();
      expect(all, isEmpty);
    });
  });

  group('PassageDAO - Client-Side Join Operations', () {
    test('getPassageWithProgressById returns passage with null progress',
        () async {
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      );

      final result = await passageDAO.getPassageWithProgressById('mat-5-44');

      expect(result, isNotNull);
      expect(result!.passage.passageId, equals('mat-5-44'));
      expect(result.passage.reference, equals('Matthew 5:44'));
      expect(result.progress, isNull);
      expect(result.hasProgress, isFalse);
      expect(result.masteryLevel, equals(0)); // Default when no progress
      expect(result.isDueForReview, isTrue); // New passages are always due
    });

    test('getPassageWithProgressById returns passage with progress', () async {
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      );

      await progressDAO.createProgress('mat-5-44');
      await progressDAO.updateMasteryLevel('mat-5-44', 3);

      final result = await passageDAO.getPassageWithProgressById('mat-5-44');

      expect(result, isNotNull);
      expect(result!.passage.passageId, equals('mat-5-44'));
      expect(result.progress, isNotNull);
      expect(result.progress!.masteryLevel, equals(3));
      expect(result.hasProgress, isTrue);
      expect(result.masteryLevel, equals(3));
    });

    test('getPassageWithProgressById returns null for non-existent passage',
        () async {
      final result =
          await passageDAO.getPassageWithProgressById('non-existent');
      expect(result, isNull);
    });

    test('getAllPassagesWithProgress returns all passages with mixed progress',
        () async {
      // Insert 3 passages
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
        PassagesCompanion.insert(
          passageId: 'jhn-3-16',
          translationId: 'niv',
          reference: 'John 3:16',
          passageText: 'For God so loved the world',
        ),
        PassagesCompanion.insert(
          passageId: 'rom-8-28',
          translationId: 'niv',
          reference: 'Romans 8:28',
          passageText: 'All things work together for good',
        ),
      ]);

      // Add progress to only 2 of them
      await progressDAO.createProgress('mat-5-44');
      await progressDAO.updateMasteryLevel('mat-5-44', 2);

      await progressDAO.createProgress('jhn-3-16');
      await progressDAO.updateMasteryLevel('jhn-3-16', 4);

      final results = await passageDAO.getAllPassagesWithProgress();

      expect(results, hasLength(3));

      // Check mat-5-44 has progress
      final mat = results.firstWhere((p) => p.passageId == 'mat-5-44');
      expect(mat.hasProgress, isTrue);
      expect(mat.masteryLevel, equals(2));

      // Check jhn-3-16 has progress
      final jhn = results.firstWhere((p) => p.passageId == 'jhn-3-16');
      expect(jhn.hasProgress, isTrue);
      expect(jhn.masteryLevel, equals(4));

      // Check rom-8-28 has no progress
      final rom = results.firstWhere((p) => p.passageId == 'rom-8-28');
      expect(rom.hasProgress, isFalse);
      expect(rom.progress, isNull);
      expect(rom.masteryLevel, equals(0));
    });

    test('getPassagesWithProgressByTranslation filters by translation',
        () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'mat-5-44-niv',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
        PassagesCompanion.insert(
          passageId: 'mat-5-44-esv',
          translationId: 'esv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      ]);

      final nivResults =
          await passageDAO.getPassagesWithProgressByTranslation('niv');
      final esvResults =
          await passageDAO.getPassagesWithProgressByTranslation('esv');

      expect(nivResults, hasLength(1));
      expect(nivResults.first.passage.translationId, equals('niv'));

      expect(esvResults, hasLength(1));
      expect(esvResults.first.passage.translationId, equals('esv'));
    });

    test('getPassagesWithProgressByMasteryLevel filters by mastery level',
        () async {
      await passageDAO.insertPassageBatch([
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        PassagesCompanion.insert(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
        PassagesCompanion.insert(
          passageId: 'test-3',
          translationId: 'niv',
          reference: 'Test 1:3',
          passageText: 'Test 3',
        ),
      ]);

      await progressDAO.createProgress('test-1');
      await progressDAO.updateMasteryLevel('test-1', 2);

      await progressDAO.createProgress('test-2');
      await progressDAO.updateMasteryLevel('test-2', 2);

      await progressDAO.createProgress('test-3');
      await progressDAO.updateMasteryLevel('test-3', 4);

      final level2 =
          await passageDAO.getPassagesWithProgressByMasteryLevel(2);

      expect(level2, hasLength(2));
      expect(level2.every((p) => p.masteryLevel == 2), isTrue);
    });

    test('getPassagesWithProgressByMasteryLevel excludes passages without progress',
        () async {
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      // No progress created, so should return empty even when searching for level 0
      final results =
          await passageDAO.getPassagesWithProgressByMasteryLevel(0);
      expect(results, isEmpty);
    });

    test('isDueForReview returns true for passages with past nextReview',
        () async {
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await progressDAO.createProgress('test-1');

      final past = DateTime.now().subtract(const Duration(days: 1));
      await progressDAO.updateSRSData(
        passageId: 'test-1',
        interval: 1,
        repetitionCount: 1,
        easeFactor: 250,
        lastReviewed: past,
        nextReview: past,
      );

      final result = await passageDAO.getPassageWithProgressById('test-1');
      expect(result!.isDueForReview, isTrue);
    });

    test('isDueForReview returns false for passages with future nextReview',
        () async {
      await passageDAO.insertPassage(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await progressDAO.createProgress('test-1');

      final now = DateTime.now();
      final future = now.add(const Duration(days: 7));
      await progressDAO.updateSRSData(
        passageId: 'test-1',
        interval: 7,
        repetitionCount: 2,
        easeFactor: 250,
        lastReviewed: now,
        nextReview: future,
      );

      final result = await passageDAO.getPassageWithProgressById('test-1');
      expect(result!.isDueForReview, isFalse);
    });
  });
}
