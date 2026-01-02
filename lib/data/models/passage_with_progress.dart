import 'package:red_letter/data/database/app_database.dart';

/// View model that decorates a static Passage with user-specific progress data.
///
/// Implements the bifurcated data model's client-side join architecture:
/// - Static passage text from global registry
/// - User-specific mastery data from progress table
///
/// Progress may be null for passages the user hasn't started yet.
class PassageWithProgress {
  /// The static passage data (text, reference, etc.)
  final Passage passage;

  /// User-specific progress data (null if never practiced)
  final UserProgress? progress;

  PassageWithProgress({
    required this.passage,
    this.progress,
  });

  /// Convenience getter for passage ID
  String get passageId => passage.passageId;

  /// Convenience getter for mastery level (0 if no progress)
  int get masteryLevel => progress?.masteryLevel ?? 0;

  /// Whether this passage has been started by the user
  bool get hasProgress => progress != null;

  /// Whether this passage is due for review
  bool get isDueForReview {
    if (progress == null) return true; // New passages are always due
    final nextReview = progress!.nextReview;
    if (nextReview == null) return true; // No scheduled review means due now
    return nextReview.isBefore(DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassageWithProgress &&
          runtimeType == other.runtimeType &&
          passage == other.passage &&
          progress == other.progress;

  @override
  int get hashCode => passage.hashCode ^ progress.hashCode;

  @override
  String toString() =>
      'PassageWithProgress(passageId: $passageId, masteryLevel: $masteryLevel)';
}
