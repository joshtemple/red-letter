import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/passage_dao.dart';

void main() {
  late AppDatabase database;
  late PassageDAO passageDAO;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    passageDAO = PassageDAO(database);
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
}
