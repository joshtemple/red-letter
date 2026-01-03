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

  PassagesCompanion createPassage({
    required String id,
    required String ref,
    required String text,
    String translation = 'niv',
    String? tags,
    String? book,
    int? chapter,
    int? startVerse,
    int? endVerse,
  }) {
    // Basic parsing for default values if not provided
    // Assumes "Book Chapter:Verse" format like "Matthew 5:44"
    if (book == null || chapter == null || startVerse == null) {
      try {
        final parts = ref.split(' ');
        if (parts.length >= 2) {
          final bookName = parts[0];
          final refParts = parts.last.split(':');
          if (refParts.length == 2) {
            book = book ?? bookName;
            chapter = chapter ?? int.parse(refParts[0]);
            startVerse = startVerse ?? int.parse(refParts[1]);
            endVerse = endVerse ?? startVerse;
          }
        }
      } catch (e) {
        // Fallback defaults
      }
    }

    return PassagesCompanion.insert(
      passageId: id,
      translationId: translation,
      reference: ref,
      passageText: text,
      tags: tags == null ? const Value.absent() : Value(tags),
      book: book ?? 'Test Book',
      chapter: chapter ?? 1,
      startVerse: startVerse ?? 1,
      endVerse: endVerse ?? 1,
    );
  }

  group('PassageDAO - Query Operations', () {
    test('getPassageById returns passage when it exists', () async {
      // Insert test passage
      await passageDAO.insertPassage(
        createPassage(
          id: 'mat-5-44',
          ref: 'Matthew 5:44',
          text: 'Love your enemies',
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

    test(
      'getPassagesByTranslation returns all passages for translation',
      () async {
        // Insert passages with different translations
        await passageDAO.insertPassageBatch([
          createPassage(
            id: 'mat-5-44',
            ref: 'Matthew 5:44',
            text: 'Love your enemies',
          ),
          createPassage(
            id: 'mat-6-9',
            ref: 'Matthew 6:9',
            text: 'Our Father in heaven',
          ),
          createPassage(
            id: 'mat-5-44-esv',
            translation: 'esv',
            ref: 'Matthew 5:44',
            text: 'Love your enemies',
          ),
        ]);

        final nivPassages = await passageDAO.getPassagesByTranslation('niv');

        expect(nivPassages, hasLength(2));
        expect(nivPassages.every((p) => p.translationId == 'niv'), isTrue);
      },
    );

    test('getPassagesByTag returns passages containing tag', () async {
      await passageDAO.insertPassageBatch([
        createPassage(
          id: 'mat-5-44',
          ref: 'Matthew 5:44',
          text: 'Love your enemies',
          tags: 'sermon-on-mount,commands,love',
        ),
        createPassage(
          id: 'mat-6-9',
          ref: 'Matthew 6:9',
          text: 'Our Father in heaven',
          tags: 'sermon-on-mount,prayer',
        ),
        createPassage(
          id: 'john-3-16',
          ref: 'John 3:16',
          text: 'For God so loved the world',
          tags: 'love,gospel',
          book: 'John',
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
        createPassage(id: 'mat-6-9', ref: 'Matthew 6:9', text: 'Our Father'),
        createPassage(
          id: 'mat-5-44',
          ref: 'Matthew 5:44',
          text: 'Love enemies',
        ),
      ]);

      final all = await passageDAO.getAllPassages();

      expect(all, hasLength(2));
      expect(
        all[0].passageId,
        equals('mat-5-44'),
      ); // Sorted by Book/Chapter/Verse
      expect(all[1].passageId, equals('mat-6-9'));
    });

    test('getAllPassagesWithProgress sorts by Book, Chapter, Verse', () async {
      await passageDAO.insertPassageBatch([
        createPassage(
          id: 'mat-5-29',
          translation: 'esv',
          ref: 'Matthew 5:29',
          text: 'Eye causes sin',
          book: 'Matthew',
          chapter: 5,
          startVerse: 29,
          endVerse: 29,
        ),
        createPassage(
          id: 'mat-5-3',
          translation: 'esv',
          ref: 'Matthew 5:3',
          text: 'Beatitudes',
          book: 'Matthew',
          chapter: 5,
          startVerse: 3,
          endVerse: 3,
        ),
        createPassage(
          id: 'acts-1-8',
          translation: 'esv',
          ref: 'Acts 1:8',
          text: 'Witnesses',
          book: 'Acts',
          chapter: 1,
          startVerse: 8,
          endVerse: 8,
        ),
      ]);

      final results = await passageDAO.getAllPassagesWithProgress();

      expect(results, hasLength(3));
      expect(
        results[0].passage.reference,
        equals('Acts 1:8'),
      ); // Acts before Matthew
      expect(
        results[1].passage.reference,
        equals('Matthew 5:3'),
      ); // 5:3 before 5:29
      expect(results[2].passage.reference, equals('Matthew 5:29'));
    });

    test('getPassageCountByTranslation returns correct count', () async {
      await passageDAO.insertPassageBatch([
        createPassage(id: 'mat-5-44', ref: 'Matthew 5:44', text: 'Test'),
        createPassage(id: 'mat-6-9', ref: 'Matthew 6:9', text: 'Test'),
        createPassage(
          id: 'mat-5-44-esv',
          translation: 'esv',
          ref: 'Matthew 5:44',
          text: 'Test',
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
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test text'),
      );

      expect(id, equals('test-1'));

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage, isNotNull);
    });

    test('insertPassageBatch adds multiple passages in transaction', () async {
      final count = await passageDAO.insertPassageBatch([
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test 1'),
        createPassage(id: 'test-2', ref: 'Test 1:2', text: 'Test 2'),
        createPassage(id: 'test-3', ref: 'Test 1:3', text: 'Test 3'),
      ]);

      expect(count, equals(3));

      final all = await passageDAO.getAllPassages();
      expect(all, hasLength(3));
    });

    test('upsertPassage inserts new passage', () async {
      await passageDAO.upsertPassage(
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Original text'),
      );

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage!.passageText, equals('Original text'));
    });

    test('upsertPassage updates existing passage', () async {
      // Insert original
      await passageDAO.insertPassage(
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Original text'),
      );

      // Upsert with new text
      await passageDAO.upsertPassage(
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Updated text'),
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
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Original'),
      );

      // Upsert batch with one update and one new insert
      await passageDAO.upsertPassageBatch([
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Updated'),
        createPassage(id: 'test-2', ref: 'Test 1:2', text: 'New'),
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
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test'),
      );

      final deleteCount = await passageDAO.deletePassageById('test-1');
      expect(deleteCount, equals(1));

      final passage = await passageDAO.getPassageById('test-1');
      expect(passage, isNull);
    });

    test('deletePassagesByTranslation removes all for translation', () async {
      await passageDAO.insertPassageBatch([
        createPassage(id: 'niv-1', ref: 'Test 1:1', text: 'Test'),
        createPassage(id: 'niv-2', ref: 'Test 1:2', text: 'Test'),
        createPassage(
          id: 'esv-1',
          translation: 'esv',
          ref: 'Test 1:1',
          text: 'Test',
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
        createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test'),
        createPassage(
          id: 'test-2',
          translation: 'esv',
          ref: 'Test 1:2',
          text: 'Test',
        ),
      ]);

      final deleteCount = await passageDAO.deleteAllPassages();
      expect(deleteCount, equals(2));

      final all = await passageDAO.getAllPassages();
      expect(all, isEmpty);
    });
  });

  group('PassageDAO - Client-Side Join Operations', () {
    test(
      'getPassageWithProgressById returns passage with null progress',
      () async {
        await passageDAO.insertPassage(
          createPassage(
            id: 'mat-5-44',
            ref: 'Matthew 5:44',
            text: 'Love your enemies',
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
      },
    );

    test('getPassageWithProgressById returns passage with progress', () async {
      await passageDAO.insertPassage(
        createPassage(
          id: 'mat-5-44',
          ref: 'Matthew 5:44',
          text: 'Love your enemies',
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

    test(
      'getPassageWithProgressById returns null for non-existent passage',
      () async {
        final result = await passageDAO.getPassageWithProgressById(
          'non-existent',
        );
        expect(result, isNull);
      },
    );

    test(
      'getAllPassagesWithProgress returns all passages with mixed progress',
      () async {
        // Insert 3 passages
        await passageDAO.insertPassageBatch([
          createPassage(
            id: 'mat-5-44',
            ref: 'Matthew 5:44',
            text: 'Love your enemies',
          ),
          createPassage(
            id: 'jhn-3-16',
            ref: 'John 3:16',
            text: 'For God so loved the world',
            book: 'John',
            chapter: 3,
            startVerse: 16,
          ),
          createPassage(
            id: 'rom-8-28',
            ref: 'Romans 8:28',
            text: 'All things work together for good',
            book: 'Romans',
            chapter: 8,
            startVerse: 28,
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
      },
    );

    test(
      'getPassagesWithProgressByTranslation filters by translation',
      () async {
        await passageDAO.insertPassageBatch([
          createPassage(
            id: 'mat-5-44-niv',
            ref: 'Matthew 5:44',
            text: 'Love your enemies',
          ),
          createPassage(
            id: 'mat-5-44-esv',
            translation: 'esv',
            ref: 'Matthew 5:44',
            text: 'Love your enemies',
          ),
        ]);

        final nivResults = await passageDAO
            .getPassagesWithProgressByTranslation('niv');
        final esvResults = await passageDAO
            .getPassagesWithProgressByTranslation('esv');

        expect(nivResults, hasLength(1));
        expect(nivResults.first.passage.translationId, equals('niv'));

        expect(esvResults, hasLength(1));
        expect(esvResults.first.passage.translationId, equals('esv'));
      },
    );

    test(
      'getPassagesWithProgressByMasteryLevel filters by mastery level',
      () async {
        await passageDAO.insertPassageBatch([
          createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test 1'),
          createPassage(id: 'test-2', ref: 'Test 1:2', text: 'Test 2'),
          createPassage(id: 'test-3', ref: 'Test 1:3', text: 'Test 3'),
        ]);

        await progressDAO.createProgress('test-1');
        await progressDAO.updateMasteryLevel('test-1', 2);

        await progressDAO.createProgress('test-2');
        await progressDAO.updateMasteryLevel('test-2', 2);

        await progressDAO.createProgress('test-3');
        await progressDAO.updateMasteryLevel('test-3', 4);

        final level2 = await passageDAO.getPassagesWithProgressByMasteryLevel(
          2,
        );

        expect(level2, hasLength(2));
        expect(level2.every((p) => p.masteryLevel == 2), isTrue);
      },
    );

    test(
      'getPassagesWithProgressByMasteryLevel excludes passages without progress',
      () async {
        await passageDAO.insertPassage(
          createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test'),
        );

        // No progress created, so should return empty even when searching for level 0
        final results = await passageDAO.getPassagesWithProgressByMasteryLevel(
          0,
        );
        expect(results, isEmpty);
      },
    );

    test(
      'isDueForReview returns true for passages with past nextReview',
      () async {
        await passageDAO.insertPassage(
          createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test'),
        );

        await progressDAO.createProgress('test-1');

        final past = DateTime.now().subtract(const Duration(days: 1));
        await progressDAO.updateFSRSData(
          passageId: 'test-1',
          stability: 1.0,
          difficulty: 5.0,
          step: null,
          state: 1, // Review state
          lastReviewed: past,
          nextReview: past,
        );

        final result = await passageDAO.getPassageWithProgressById('test-1');
        expect(result!.isDueForReview, isTrue);
      },
    );

    test(
      'isDueForReview returns false for passages with future nextReview',
      () async {
        await passageDAO.insertPassage(
          createPassage(id: 'test-1', ref: 'Test 1:1', text: 'Test'),
        );

        await progressDAO.createProgress('test-1');

        final now = DateTime.now();
        final future = now.add(const Duration(days: 7));
        await progressDAO.updateFSRSData(
          passageId: 'test-1',
          stability: 7.0,
          difficulty: 5.0,
          step: null,
          state: 1, // Review state
          lastReviewed: now,
          nextReview: future,
        );

        final result = await passageDAO.getPassageWithProgressById('test-1');
        expect(result!.isDueForReview, isFalse);
      },
    );
  });
}
