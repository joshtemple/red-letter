import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/passage_dao.dart';
import 'package:red_letter/data/seed_data_loader.dart';

/// Database seeder for populating initial passage data.
///
/// Provides idempotent seeding logic that can be safely called multiple times
/// without duplicating data. Typically invoked during database onCreate.
class DatabaseSeeder {
  final AppDatabase database;
  late final PassageDAO _passageDAO;

  DatabaseSeeder(this.database) {
    _passageDAO = PassageDAO(database);
  }

  /// Seeds the database with initial ESV translation data.
  ///
  /// This method is idempotent - it checks if the translation already exists
  /// before inserting data, ensuring safe execution on app reinstalls or
  /// database migrations.
  ///
  /// Returns the number of passages inserted (0 if already seeded).
  Future<int> seedESVTranslation() async {
    return _seedTranslation(
      translationId: 'esv',
      loader: SeedDataLoader.loadESVCompanions,
    );
  }

  /// Seeds all available translations.
  ///
  /// Currently only seeds ESV translation. Future translations can be added
  /// here as they become available.
  ///
  /// Returns the total number of passages inserted across all translations.
  Future<int> seedAllTranslations() async {
    int totalInserted = 0;

    // Seed ESV translation
    totalInserted += await seedESVTranslation();

    // Future translations can be added here:
    // totalInserted += await seedNIVTranslation();
    // totalInserted += await seedKJVTranslation();

    return totalInserted;
  }

  /// Generic translation seeding logic.
  ///
  /// Checks if the translation already exists by counting passages with the
  /// given translationId. If count is 0, loads and inserts seed data.
  ///
  /// This ensures idempotent behavior - multiple calls won't duplicate data.
  Future<int> _seedTranslation({
    required String translationId,
    required Future<List<PassagesCompanion>> Function() loader,
  }) async {
    // Check if translation already seeded
    final existingCount = await _passageDAO.getPassageCountByTranslation(translationId);

    if (existingCount > 0) {
      // Translation already seeded, skip
      return 0;
    }

    // Load seed data
    final companions = await loader();

    // Insert in batch for performance
    final insertedCount = await _passageDAO.insertPassageBatch(companions);

    return insertedCount;
  }

  /// Checks if any seed data has been loaded.
  ///
  /// Useful for determining if this is a fresh database or if seeding has
  /// already occurred. Returns true if at least one passage exists.
  Future<bool> isSeeded() async {
    final allPassages = await _passageDAO.getAllPassages();
    return allPassages.isNotEmpty;
  }

  /// Reseeds a specific translation by deleting existing data and reloading.
  ///
  /// WARNING: This will cascade delete all user progress for passages in this
  /// translation! Only use for development/testing or with explicit user consent.
  ///
  /// Returns the number of passages inserted.
  Future<int> reseedTranslation(String translationId) async {
    // Delete existing translation data (cascades to user progress!)
    await _passageDAO.deletePassagesByTranslation(translationId);

    // Reseed based on translation ID
    switch (translationId.toLowerCase()) {
      case 'esv':
        return seedESVTranslation();
      default:
        throw ArgumentError('Unknown translation ID: $translationId');
    }
  }
}
