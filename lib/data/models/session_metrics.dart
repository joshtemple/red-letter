import 'package:fsrs/fsrs.dart' as fsrs;

/// Metrics captured during a practice session for a passage.
///
/// These metrics are used to calculate an FSRS rating that reflects
/// the user's recall performance.
class SessionMetrics {
  /// The passage text that was practiced
  final String passageText;

  /// The user's typed input
  final String userInput;

  /// Time taken to complete the passage (in milliseconds)
  final int durationMs;

  /// Levenshtein edit distance between passage and user input
  final int levenshteinDistance;

  SessionMetrics({
    required this.passageText,
    required this.userInput,
    required this.durationMs,
    required this.levenshteinDistance,
  });

  /// Calculate typing speed in characters per minute (CPM)
  double get cpm {
    if (durationMs <= 0) return 0.0;
    final minutes = durationMs / 60000.0;
    return userInput.length / minutes;
  }

  /// Calculate typing speed in words per minute (WPM)
  /// Assumes average word length of 5 characters
  double get wpm => cpm / 5.0;

  /// Calculate accuracy as a percentage (0.0 to 1.0)
  ///
  /// Uses Levenshtein distance normalized by passage length.
  /// Returns 1.0 for perfect accuracy, 0.0 for completely wrong.
  double get accuracy {
    if (passageText.isEmpty) return 1.0;
    final maxDistance = passageText.length;
    return (maxDistance - levenshteinDistance) / maxDistance;
  }

  /// Calculate recall quality score (0.0 to 1.0)
  ///
  /// Combines accuracy and speed into a single quality metric.
  /// - Accuracy is weighted more heavily (70%)
  /// - Speed is weighted less (30%)
  ///
  /// This reflects the principle that correct recall matters more
  /// than fast recall.
  double get recallQuality {
    // Normalize speed: 40 WPM is baseline, 80+ WPM is excellent
    final normalizedSpeed = (wpm / 80.0).clamp(0.0, 1.0);

    // Weighted combination: accuracy matters more than speed
    return (accuracy * 0.7) + (normalizedSpeed * 0.3);
  }

  /// Map session metrics to an FSRS rating.
  ///
  /// The mapping reflects the user's recall performance:
  ///
  /// **Again (1)**: Failed recall
  /// - Accuracy < 70% OR extremely slow (< 10 WPM)
  /// - User struggled significantly or couldn't remember
  ///
  /// **Hard (2)**: Difficult recall
  /// - Accuracy 70-84% OR slow typing (10-25 WPM)
  /// - User remembered but with considerable effort
  ///
  /// **Good (3)**: Standard recall
  /// - Accuracy 85-94% AND moderate speed (25-50 WPM)
  /// - User recalled after brief hesitation
  ///
  /// **Easy (4)**: Effortless recall
  /// - Accuracy ≥ 95% AND fast typing (≥ 50 WPM)
  /// - User demonstrated mastery
  ///
  /// The thresholds are designed to be forgiving early in learning
  /// while still distinguishing true mastery.
  fsrs.Rating toFSRSRating() {
    // Critical failure conditions - return Again immediately
    if (accuracy < 0.70 || wpm < 15) {
      return fsrs.Rating.again;
    }

    // Calculate overall recall quality
    final quality = recallQuality;

    // Map quality to FSRS rating with strict thresholds
    if (accuracy >= 0.95 && wpm >= 60) {
      // Effortless recall: near-perfect accuracy + fast speed
      return fsrs.Rating.easy;
    } else if (accuracy >= 0.90 && wpm >= 40) {
      // Standard recall: excellent accuracy, good speed
      return fsrs.Rating.good;
    } else if (accuracy >= 0.85 && wpm >= 35) {
      // Also good: very good accuracy, moderate speed
      return fsrs.Rating.good;
    } else if (accuracy >= 0.70 && wpm >= 20) {
      // Difficult recall: acceptable but struggled
      return fsrs.Rating.hard;
    } else {
      // Failed recall: below threshold
      return fsrs.Rating.again;
    }
  }

  @override
  String toString() {
    return 'SessionMetrics('
        'accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, '
        'wpm: ${wpm.toStringAsFixed(1)}, '
        'quality: ${(recallQuality * 100).toStringAsFixed(1)}%, '
        'rating: ${toFSRSRating()})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionMetrics &&
          runtimeType == other.runtimeType &&
          passageText == other.passageText &&
          userInput == other.userInput &&
          durationMs == other.durationMs &&
          levenshteinDistance == other.levenshteinDistance;

  @override
  int get hashCode =>
      passageText.hashCode ^
      userInput.hashCode ^
      durationMs.hashCode ^
      levenshteinDistance.hashCode;
}
