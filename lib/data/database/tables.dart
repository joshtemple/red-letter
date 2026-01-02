import 'package:drift/drift.dart';

/// Global Registry table for static scripture passages.
///
/// This table contains immutable passage text shared across all users.
/// The bifurcated data model keeps static content separate from user progress
/// to minimize storage and maximize scalability.
@DataClassName('Passage')
class Passages extends Table {
  /// Unique passage identifier (e.g., "mat-5-44" for Matthew 5:44)
  TextColumn get passageId => text()();

  /// Translation identifier (e.g., "niv", "esv", "kjv")
  TextColumn get translationId => text()();

  /// Human-readable scripture reference (e.g., "Matthew 5:44")
  TextColumn get reference => text()();

  /// The actual scripture text to memorize
  TextColumn get text => text()();

  /// Optional URL to visual mnemonic aid (nullable)
  TextColumn get mnemonicUrl => text().nullable()();

  /// Comma-separated tags for categorization (e.g., "sermon-on-mount,commands")
  TextColumn get tags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {passageId};

  @override
  List<String> get customConstraints => [
    // Index for fast translation-based queries
    'CREATE INDEX IF NOT EXISTS idx_passages_translation ON passages(translation_id)',
    // Index for tag-based filtering (useful for future features)
    'CREATE INDEX IF NOT EXISTS idx_passages_tags ON passages(tags)',
  ];
}

/// User-specific progress tracking table.
///
/// Each row represents one user's progress on one passage.
/// Uses foreign key to Passages table for client-side join architecture.
@DataClassName('UserProgress')
class UserProgressTable extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key reference to Passages.passageId
  TextColumn get passageId => text()();

  /// Current mastery level (0-4: new, learning, familiar, mastered, locked-in)
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();

  /// SRS: Days until next review
  IntColumn get interval => integer().withDefault(const Constant(0))();

  /// SRS: Number of successful repetitions
  IntColumn get repetitionCount => integer().withDefault(const Constant(0))();

  /// SRS: Ease factor (multiplier for interval growth, stored as int * 100)
  IntColumn get easeFactor => integer().withDefault(const Constant(250))();

  /// Timestamp of last review (Unix epoch seconds)
  DateTimeColumn get lastReviewed => dateTime().nullable()();

  /// Timestamp when next review is due (Unix epoch seconds)
  DateTimeColumn get nextReview => dateTime().nullable()();

  /// User's semantic reflection text (enforces understanding before rote practice)
  TextColumn get semanticReflection => text().nullable()();

  /// Timestamp of last cloud sync (Unix epoch seconds, nullable for offline-only users)
  DateTimeColumn get lastSync => dateTime().nullable()();

  @override
  List<String> get customConstraints => [
    // Foreign key constraint to Passages table
    'FOREIGN KEY (passage_id) REFERENCES passages(passage_id) ON DELETE CASCADE',
    // Index for fast passageId lookups (used in client-side joins)
    'CREATE INDEX IF NOT EXISTS idx_user_progress_passage ON user_progress_table(passage_id)',
    // Index for SRS review queue queries (find passages due for review)
    'CREATE INDEX IF NOT EXISTS idx_user_progress_next_review ON user_progress_table(next_review)',
    // Index for mastery level filtering
    'CREATE INDEX IF NOT EXISTS idx_user_progress_mastery ON user_progress_table(mastery_level)',
  ];
}
