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
      expect(afterCount, 109); // Matthew 5:3-7:29 = 109 verses
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
      expect(insertedCount, 109);

      // Verify passages exist
      final passages = await passageDAO.getPassagesByTranslation('esv');
      expect(passages.length, 109);
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
      final passage = await passageDAO.getPassageById('mat-5-44');
      expect(passage, isNotNull);
      expect(passage!.passageId, 'mat-5-44');
      expect(passage.translationId, 'esv');
      expect(passage.reference, 'Matthew 5:44');
      expect(passage.passageText, contains('Love your enemies'));
      expect(passage.tags, contains('sermon-on-mount'));
      expect(passage.tags, contains('love-enemies'));
      expect(passage.tags, contains('commands'));
    });

    test('seeded passages cover Matthew 5-7 range', () async {
      await seeder.seedESVTranslation();

      // Check first verse (Matthew 5:3)
      final firstVerse = await passageDAO.getPassageById('mat-5-3');
      expect(firstVerse, isNotNull);
      expect(firstVerse!.passageText, contains('Blessed are the poor in spirit'));

      // Check middle verse (Matthew 6:9 - Lord's Prayer)
      final middleVerse = await passageDAO.getPassageById('mat-6-9');
      expect(middleVerse, isNotNull);
      expect(middleVerse!.passageText, contains('Our Father in heaven'));

      // Check last verse (Matthew 7:29)
      final lastVerse = await passageDAO.getPassageById('mat-7-29');
      expect(lastVerse, isNotNull);
      expect(lastVerse!.passageText, contains('authority'));
    });

    test('seeded passages have proper tags', () async {
      await seeder.seedESVTranslation();

      // Check beatitudes tag
      final beatitudes = await passageDAO.getPassagesByTag('beatitudes');
      expect(beatitudes.length, greaterThanOrEqualTo(9)); // At least 9 beatitudes

      // Check lords-prayer tag
      final lordsPrayer = await passageDAO.getPassagesByTag('lords-prayer');
      expect(lordsPrayer.length, greaterThanOrEqualTo(5)); // Lord's Prayer verses

      // Check commands tag
      final commands = await passageDAO.getPassagesByTag('commands');
      expect(commands.length, greaterThan(0)); // Many command verses
    });

    test('reseedTranslation deletes and reloads data', () async {
      // Initial seed
      await seeder.seedESVTranslation();
      final initialCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(initialCount, 109);

      // Reseed
      final reseedCount = await seeder.reseedTranslation('esv');
      expect(reseedCount, 109);

      // Verify count is the same
      final finalCount = await passageDAO.getPassageCountByTranslation('esv');
      expect(finalCount, initialCount);
    });

    test('reseedTranslation throws for unknown translation', () async {
      expect(
        () => seeder.reseedTranslation('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('AppDatabase integration', () {
    test('database auto-seeds on creation', () async {
      // Create a fresh database with seeding enabled
      final freshDb = AppDatabase.forTesting(NativeDatabase.memory(), skipSeeding: false);
      final freshPassageDAO = PassageDAO(freshDb);

      // Give it a moment to complete onCreate and seeding
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify passages were auto-seeded
      final count = await freshPassageDAO.getPassageCountByTranslation('esv');
      expect(count, 109);

      await freshDb.close();
    });
  });
}
