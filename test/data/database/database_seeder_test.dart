import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/database_seeder.dart';
import 'package:red_letter/data/database/passage_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseSeeder seeder;
  late PassageDAO passageDAO;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    seeder = DatabaseSeeder(database);
    passageDAO = PassageDAO(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DatabaseSeeder', () {
    test('seedESVTranslation inserts passages on first run', () async {
      // Verify database is empty
      final beforeCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(beforeCount, 0);

      // Seed ESV translation
      final insertedCount = await seeder.seedESVTranslation();

      // Verify passages were inserted
      expect(insertedCount, greaterThan(0));

      // Verify count matches
      final afterCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(afterCount, insertedCount);
      expect(afterCount, 68); // Updated to match new manually curated dataset
    });

    test('seedESVTranslation is idempotent', () async {
      // First seeding
      final firstCount = await seeder.seedESVTranslation();
      expect(firstCount, greaterThan(0));

      // Second seeding should insert 0 (already exists)
      final secondCount = await seeder.seedESVTranslation();
      expect(secondCount, 0);

      // Verify total count hasn't changed
      final totalCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(totalCount, firstCount);
    });

    test('seedAllTranslations seeds ESV', () async {
      final insertedCount = await seeder.seedAllTranslations();
      expect(insertedCount, 68);

      // Verify passages exist
      final passages = await passageDAO.getPassagesByTranslation('esv');
      expect(passages.length, 68);
    });

    test('isSeeded returns false for empty database', () async {
      final seeded = await seeder.isSeeded();
      expect(seeded, false);
    });

    test('isSeeded returns true after seeding', () async {
      await seeder.seedESVTranslation();
      final seeded = await seeder.isSeeded();
      expect(seeded, true);
    });

    test('seeded passages have correct structure', () async {
      await seeder.seedESVTranslation();

      // Get a specific passage to verify structure
      // Note: Data set updated to ranges, checking mat-5-44-47
      final passage = await passageDAO.getPassageById('mat-5-44-47');
      expect(passage, isNotNull);
      expect(passage!.passageId, 'mat-5-44-47');
      expect(passage.translationId, 'esv');
      expect(passage.reference, 'Matthew 5:44-47');
      expect(passage.passageText, contains('Love your enemies'));
      // Tags are not currently in the JSON
      // expect(passage.tags, contains('love-enemies'));
    });

    test('seeded passages cover key commands', () async {
      await seeder.seedESVTranslation();

      // Check for a few expected passages from the new list
      final lukePassage = await passageDAO.getPassageById('luk-3-10-14');
      expect(lukePassage, isNotNull);
      expect(lukePassage!.passageText, contains('Whoever has two tunics'));

      final matthewPassage = await passageDAO.getPassageById('mat-5-39-42');
      expect(matthewPassage, isNotNull);
      expect(
        matthewPassage!.passageText,
        contains('Do not resist the one who is evil'),
      );
    });

    // Tag tests removed as tags are not in current dataset

    test('reseedTranslation deletes and reloads data', () async {
      // Initial seed
      await seeder.seedESVTranslation();
      final initialCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(initialCount, 68);

      // Reseed
      final reseedCount = await seeder.reseedTranslation('esv');
      expect(reseedCount, 68);

      // Verify count is the same
      final finalCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(finalCount, initialCount);
    });

    test('reseedTranslation throws for unknown translation', () async {
      expect(() => seeder.reseedTranslation('unknown'), throwsArgumentError);
    });
  });

  group('AppDatabase integration', () {
    test('database auto-seeds on creation', () async {
      // Create a fresh database with seeding enabled
      final freshDb = AppDatabase.forTesting(
        NativeDatabase.memory(),
        skipSeeding: false,
      );
      final freshPassageDAO = PassageDAO(freshDb);

      // Give it a moment to complete onCreate and seeding
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify passages were auto-seeded
      final count = await freshPassageDAO.getPassageCountByTranslation('esv');
      expect(count, 68);

      await freshDb.close();
    });
  });
}
