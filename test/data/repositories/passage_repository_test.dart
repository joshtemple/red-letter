import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';

/// Helper to create a test passage companion
PassagesCompanion createTestPassage({
  required String passageId,
  required String translationId,
  required String reference,
  required String passageText,
  Value<String> tags = const Value.absent(),
}) {
  return PassagesCompanion.insert(
    passageId: passageId,
    translationId: translationId,
    reference: reference,
    passageText: passageText,
    book: 'TestBook',
    chapter: 1,
    startVerse: 1,
    endVerse: 1,
    tags: tags,
  );
}

void main() {
  late AppDatabase database;
  late PassageRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PassageRepository.fromDatabase(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('PassageRepository - Passage Queries', () {
    test('getPassage returns passage when it exists', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      );

      final passage = await repository.getPassage('mat-5-44');

      expect(passage, isNotNull);
      expect(passage!.passageId, equals('mat-5-44'));
      expect(passage.reference, equals('Matthew 5:44'));
    });

    test('getPassage returns null when passage does not exist', () async {
      final passage = await repository.getPassage('non-existent');
      expect(passage, isNull);
    });

    test('getPassagesByTranslation filters by translation', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'mat-5-44-niv',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
        createTestPassage(
          passageId: 'mat-5-44-esv',
          translationId: 'esv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      ]);

      final nivPassages = await repository.getPassagesByTranslation('niv');
      final esvPassages = await repository.getPassagesByTranslation('esv');

      expect(nivPassages, hasLength(1));
      expect(nivPassages.first.translationId, equals('niv'));

      expect(esvPassages, hasLength(1));
      expect(esvPassages.first.translationId, equals('esv'));
    });

    test('getPassagesByTag returns passages containing tag', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
          tags: const Value('sermon-on-mount,commands'),
        ),
        createTestPassage(
          passageId: 'jhn-3-16',
          translationId: 'niv',
          reference: 'John 3:16',
          passageText: 'For God so loved',
          tags: const Value('gospel'),
        ),
      ]);

      final commandsPassages = await repository.getPassagesByTag('commands');

      expect(commandsPassages, hasLength(1));
      expect(commandsPassages.first.passageId, equals('mat-5-44'));
    });

    test('getPassageCount returns correct count', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test',
        ),
      ]);

      final count = await repository.getPassageCount('niv');
      expect(count, equals(2));
    });
  });

  group('PassageRepository - Passage with Progress Queries', () {
    test('getPassageWithProgress returns passage with null progress', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      );

      final result = await repository.getPassageWithProgress('mat-5-44');

      expect(result, isNotNull);
      expect(result!.passage.passageId, equals('mat-5-44'));
      expect(result.progress, isNull);
      expect(result.hasProgress, isFalse);
    });

    test('getPassageWithProgress returns passage with progress', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
      );

      await repository.createProgress('mat-5-44');
      await repository.updateMasteryLevel('mat-5-44', 3);

      final result = await repository.getPassageWithProgress('mat-5-44');

      expect(result, isNotNull);
      expect(result!.hasProgress, isTrue);
      expect(result.masteryLevel, equals(3));
    });

    test('getAllPassagesWithProgress returns all passages', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'mat-5-44',
          translationId: 'niv',
          reference: 'Matthew 5:44',
          passageText: 'Love your enemies',
        ),
        createTestPassage(
          passageId: 'jhn-3-16',
          translationId: 'niv',
          reference: 'John 3:16',
          passageText: 'For God so loved',
        ),
      ]);

      await repository.createProgress('mat-5-44');
      await repository.updateMasteryLevel('mat-5-44', 2);

      final results = await repository.getAllPassagesWithProgress();

      expect(results, hasLength(2));

      final withProgress = results.firstWhere((p) => p.passageId == 'mat-5-44');
      expect(withProgress.hasProgress, isTrue);
      expect(withProgress.masteryLevel, equals(2));

      final withoutProgress = results.firstWhere(
        (p) => p.passageId == 'jhn-3-16',
      );
      expect(withoutProgress.hasProgress, isFalse);
    });

    test(
      'getPassagesWithProgressByTranslation filters by translation',
      () async {
        await repository.insertPassageBatch([
          createTestPassage(
            passageId: 'mat-5-44-niv',
            translationId: 'niv',
            reference: 'Matthew 5:44',
            passageText: 'Love your enemies',
          ),
          createTestPassage(
            passageId: 'mat-5-44-esv',
            translationId: 'esv',
            reference: 'Matthew 5:44',
            passageText: 'Love your enemies',
          ),
        ]);

        final nivResults = await repository
            .getPassagesWithProgressByTranslation('niv');

        expect(nivResults, hasLength(1));
        expect(nivResults.first.passage.translationId, equals('niv'));
      },
    );

    test('getPassagesWithProgressByMasteryLevel filters by level', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
      ]);

      await repository.createProgress('test-1');
      await repository.updateMasteryLevel('test-1', 2);

      await repository.createProgress('test-2');
      await repository.updateMasteryLevel('test-2', 3);

      final level2 = await repository.getPassagesWithProgressByMasteryLevel(2);

      expect(level2, hasLength(1));
      expect(level2.first.masteryLevel, equals(2));
    });
  });

  group('PassageRepository - Progress Queries', () {
    test('getProgress returns progress when it exists', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await repository.createProgress('test-1');

      final progress = await repository.getProgress('test-1');

      expect(progress, isNotNull);
      expect(progress!.passageId, equals('test-1'));
      expect(progress.masteryLevel, equals(0)); // Default
    });

    test('getProgress returns null when no progress exists', () async {
      final progress = await repository.getProgress('non-existent');
      expect(progress, isNull);
    });

    test('getDueForReview returns passages due for review', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
      ]);

      await repository.createProgress('test-1');
      await repository.createProgress('test-2');

      final past = DateTime.now().subtract(const Duration(days: 1));
      await repository.recordReview(
        passageId: 'test-1',
        masteryLevel: 1,
        stability: 1.0,
        difficulty: 5.0,
        step: null,
        state: 1, // Review state
        lastReviewed: past,
        nextReview: past, // Due in the past
      );

      final due = await repository.getDueForReview();

      // test-1 (past) and test-2 (null nextReview) should both be due
      expect(due, hasLength(2));
    });

    test('getMasteryLevelCounts returns count map', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
        createTestPassage(
          passageId: 'test-3',
          translationId: 'niv',
          reference: 'Test 1:3',
          passageText: 'Test 3',
        ),
      ]);

      await repository.createProgress('test-1');
      await repository.updateMasteryLevel('test-1', 0);

      await repository.createProgress('test-2');
      await repository.updateMasteryLevel('test-2', 2);

      await repository.createProgress('test-3');
      await repository.updateMasteryLevel('test-3', 2);

      final counts = await repository.getMasteryLevelCounts();

      expect(counts[0], equals(1));
      expect(counts[2], equals(2));
    });

    test('getAllProgress returns all progress entries', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
      ]);

      await repository.createProgress('test-1');
      await repository.createProgress('test-2');

      final allProgress = await repository.getAllProgress();

      expect(allProgress, hasLength(2));
    });
  });

  group('PassageRepository - Progress Mutations', () {
    test('createProgress creates entry with default values', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await repository.createProgress('test-1');

      final progress = await repository.getProgress('test-1');

      expect(progress, isNotNull);
      expect(progress!.masteryLevel, equals(0));
      expect(progress.stability, equals(0.0));
      expect(progress.difficulty, equals(5.0));
      expect(progress.state, equals(0)); // Learning state
    });

    test('updateMasteryLevel updates the mastery level', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await repository.createProgress('test-1');
      await repository.updateMasteryLevel('test-1', 4);

      final progress = await repository.getProgress('test-1');
      expect(progress!.masteryLevel, equals(4));
    });

    test('recordReview updates both mastery and SRS data', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await repository.createProgress('test-1');

      final lastReviewed = DateTime.now();
      final nextReview = lastReviewed.add(const Duration(days: 5));

      await repository.recordReview(
        passageId: 'test-1',
        masteryLevel: 2,
        stability: 5.8,
        difficulty: 4.5,
        step: null,
        state: 1, // Review state
        lastReviewed: lastReviewed,
        nextReview: nextReview,
      );

      final progress = await repository.getProgress('test-1');
      expect(progress!.masteryLevel, equals(2));
      expect(progress.stability, equals(5.8));
      expect(progress.difficulty, equals(4.5));
      expect(progress.state, equals(1));
    });

    test('updateSemanticReflection stores reflection text', () async {
      await repository.insertPassage(
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test',
        ),
      );

      await repository.createProgress('test-1');
      await repository.updateSemanticReflection(
        'test-1',
        'This passage teaches about love',
      );

      final progress = await repository.getProgress('test-1');
      expect(
        progress!.semanticReflection,
        equals('This passage teaches about love'),
      );
    });

    test('deleteAllProgress removes all progress', () async {
      await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
      ]);

      await repository.createProgress('test-1');
      await repository.createProgress('test-2');

      final deleteCount = await repository.deleteAllProgress();
      expect(deleteCount, equals(2));

      final allProgress = await repository.getAllProgress();
      expect(allProgress, isEmpty);
    });
  });

  group('PassageRepository - Batch Operations', () {
    test('insertPassageBatch inserts multiple passages efficiently', () async {
      final count = await repository.insertPassageBatch([
        createTestPassage(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test 1',
        ),
        createTestPassage(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 1:2',
          passageText: 'Test 2',
        ),
        createTestPassage(
          passageId: 'test-3',
          translationId: 'niv',
          reference: 'Test 1:3',
          passageText: 'Test 3',
        ),
      ]);

      expect(count, equals(3));

      final allPassages = await repository.getPassagesByTranslation('niv');
      expect(allPassages, hasLength(3));
    });
  });

  group('PassageRepository - Reactive Streams', () {
    test(
      'watchPassageWithProgress emits updates when progress changes',
      () async {
        await repository.insertPassage(
          createTestPassage(
            passageId: 'mat-5-44',
            translationId: 'niv',
            reference: 'Matthew 5:44',
            passageText: 'Love your enemies',
          ),
        );

        // Create stream
        final stream = repository.watchPassageWithProgress('mat-5-44');

        // Expect first event (passage without progress)
        expect(
          stream,
          emitsInOrder([
            isNotNull, // Initial state
            predicate<PassageWithProgress?>(
              (p) => p != null && p.hasProgress,
            ), // After update
          ]),
        );

        // Trigger update
        await Future.delayed(const Duration(milliseconds: 50));
        await repository.createProgress('mat-5-44');
      },
    );

    test(
      'watchAllPassagesWithProgress emits updates when new progress added',
      () async {
        await repository.insertPassageBatch([
          createTestPassage(
            passageId: 'p1',
            translationId: 'niv',
            reference: 'Ref 1',
            passageText: 'Text 1',
          ),
          createTestPassage(
            passageId: 'p2',
            translationId: 'niv',
            reference: 'Ref 2',
            passageText: 'Text 2',
          ),
        ]);

        final stream = repository.watchAllPassagesWithProgress();

        expect(
          stream,
          emitsInOrder([
            hasLength(2), // Initial state
            hasLength(2), // After update (still 2 items, but content changed)
          ]),
        );

        // Trigger update
        await Future.delayed(const Duration(milliseconds: 50));
        await repository.createProgress('p1');
      },
    );
  });
}
