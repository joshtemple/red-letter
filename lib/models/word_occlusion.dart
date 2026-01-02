import 'dart:math';
import 'package:red_letter/models/passage.dart';

/// Manages word occlusion for Scaffolding Mode practice.
///
/// Randomly hides 30-50% of words in a passage to test recall ability.
/// Each instance generates a different pattern of hidden words.
class WordOcclusion {
  final Passage passage;
  final Set<int> hiddenIndices;
  final double occlusionRatio;

  WordOcclusion._({
    required this.passage,
    required this.hiddenIndices,
    required this.occlusionRatio,
  });

  /// Generates a new word occlusion pattern.
  ///
  /// - [passage]: The passage to occlude words from
  /// - [minRatio]: Minimum percentage of words to hide (default: 0.3 = 30%)
  /// - [maxRatio]: Maximum percentage of words to hide (default: 0.5 = 50%)
  /// - [seed]: Optional random seed for reproducible patterns (useful for testing)
  factory WordOcclusion.generate({
    required Passage passage,
    double minRatio = 0.3,
    double maxRatio = 0.5,
    int? seed,
  }) {
    assert(minRatio >= 0 && minRatio <= 1, 'minRatio must be between 0 and 1');
    assert(maxRatio >= 0 && maxRatio <= 1, 'maxRatio must be between 0 and 1');
    assert(minRatio <= maxRatio, 'minRatio must be <= maxRatio');

    final random = seed != null ? Random(seed) : Random();

    // Calculate actual occlusion ratio (random between min and max)
    final actualRatio = minRatio + random.nextDouble() * (maxRatio - minRatio);

    // Calculate how many words to hide
    final wordCount = passage.words.length;
    final hideCount = (wordCount * actualRatio).round();

    // Generate random indices to hide
    final allIndices = List.generate(wordCount, (i) => i);
    allIndices.shuffle(random);
    final hiddenIndices = Set<int>.from(allIndices.take(hideCount));

    return WordOcclusion._(
      passage: passage,
      hiddenIndices: hiddenIndices,
      occlusionRatio: actualRatio,
    );
  }

  /// Returns true if the word at [index] should be hidden.
  bool isWordHidden(int index) {
    return hiddenIndices.contains(index);
  }

  /// Returns the display text for the word at [index].
  ///
  /// If the word is hidden, returns an underscore placeholder.
  /// Otherwise, returns the actual word.
  String getDisplayWord(int index) {
    if (index < 0 || index >= passage.words.length) {
      throw RangeError('Index $index out of range for passage with ${passage.words.length} words');
    }

    if (isWordHidden(index)) {
      final wordLength = passage.words[index].length;
      return '_' * wordLength; // Match the length of the hidden word
    }

    return passage.words[index];
  }

  /// Returns the full passage text with hidden words replaced by underscores.
  String getDisplayText() {
    final displayWords = <String>[];
    for (int i = 0; i < passage.words.length; i++) {
      displayWords.add(getDisplayWord(i));
    }
    return displayWords.join(' ');
  }

  /// Returns the number of words that are currently hidden.
  int get hiddenWordCount => hiddenIndices.length;

  /// Returns the total number of words in the passage.
  int get totalWordCount => passage.words.length;

  /// Returns the number of words that are currently visible.
  int get visibleWordCount => totalWordCount - hiddenWordCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordOcclusion &&
        other.passage == passage &&
        other.hiddenIndices.length == hiddenIndices.length &&
        other.hiddenIndices.every((i) => hiddenIndices.contains(i)) &&
        other.occlusionRatio == occlusionRatio;
  }

  @override
  int get hashCode {
    return Object.hash(
      passage,
      hiddenIndices.length,
      occlusionRatio,
    );
  }
}
