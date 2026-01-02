import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'database_seeder.dart';

part 'app_database.g.dart';

/// Main database class for Red Letter app.
///
/// Implements the bifurcated data model with:
/// - Passages: Global registry of static scripture text
/// - UserProgressTable: Per-user progress tracking with SRS data
///
/// Uses client-side joins to decorate passages with user progress.
@DriftDatabase(tables: [Passages, UserProgressTable])
class AppDatabase extends _$AppDatabase {
  /// Whether to skip seeding data (used in tests)
  final bool skipSeeding;

  AppDatabase() : skipSeeding = false, super(_openConnection());

  /// Constructor for testing with custom QueryExecutor
  AppDatabase.forTesting(QueryExecutor executor, {this.skipSeeding = true})
      : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create indexes for performance
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_passages_translation ON passages(translation_id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_passages_tags ON passages(tags)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_user_progress_passage ON user_progress_table(passage_id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_user_progress_next_review ON user_progress_table(next_review)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_user_progress_mastery ON user_progress_table(mastery_level)',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will go here
        // Example: if (from < 2) { await m.addColumn(...); }
      },
      beforeOpen: (details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated && !skipSeeding) {
          // Database was just created, seed initial data
          final seeder = DatabaseSeeder(this);
          await seeder.seedAllTranslations();
        }
      },
    );
  }
}

/// Opens a connection to the SQLite database.
///
/// For production: Uses app documents directory
/// Location: {app_documents}/red_letter.db
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'red_letter.db'));
    return NativeDatabase(file);
  });
}
