import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/clause_segmentation.dart';

/// The mode/round of cloze practice in the acquisition ladder.
enum ClozeRound {
  /// Round 1: Remove 1-2 non-trivial content words per clause randomly
  randomWordPerClause,

  /// Round 2: Hide one entire clause at a time, rotating through all clauses
  rotatingClauseDeletion,

  /// Round 3: Show only the first 2 words of every clause, hide all others
  firstTwoWordsScaffolding,
}

/// Manages word occlusion for the Advanced Acquisition Ladder.
///
/// Supports three progressive scaffolding rounds:
/// 1. Random word removal per clause (1-2 words)
/// 2. Rotating clause deletion (hide entire clauses)
/// 3. First-2-words scaffolding (show only first 2 words of each clause)
class ClozeOcclusion {
  final Passage passage;
  final ClauseSegmentation segmentation;
  final ClozeRound round;
  final Set<int> hiddenIndices;

  /// For Round 2: which clause index is currently hidden (rotates)
  final int? hiddenClauseIndex;

  ClozeOcclusion._({
    required this.passage,
    required this.segmentation,
    required this.round,
    required this.hiddenIndices,
    this.hiddenClauseIndex,
  });

  /// Creates Round 1: Random word removal per clause.
  ///
  /// Removes [wordsPerClause] non-trivial words from each clause randomly.
  /// Skips trivial words (and, the, a, etc.) to force meaningful recall.
  factory ClozeOcclusion.randomWordPerClause({
    required Passage passage,
    int wordsPerClause = 1,
    int? seed,
  }) {
    final segmentation = ClauseSegmentation.fromPassage(passage);
    final random = seed != null ? Random(seed) : Random();
    final hiddenIndices = <int>{};

    // For each clause, hide 1-2 random non-trivial words
    for (final clause in segmentation.clauses) {
      final contentWordIndices = _getContentWordIndices(clause, passage);

      if (contentWordIndices.isEmpty) continue;

      // Randomly select up to wordsPerClause words to hide
      final shuffled = List<int>.from(contentWordIndices)..shuffle(random);
      final toHide = shuffled.take(
        min(wordsPerClause, contentWordIndices.length),
      );

      hiddenIndices.addAll(toHide);
    }

    return ClozeOcclusion._(
      passage: passage,
      segmentation: segmentation,
      round: ClozeRound.randomWordPerClause,
      hiddenIndices: hiddenIndices,
    );
  }

  /// Creates Round 2: Rotating clause deletion.
  ///
  /// Hides one entire clause at a time. The [clauseIndex] parameter
  /// specifies which clause to hide (rotates through all clauses).
  factory ClozeOcclusion.rotatingClauseDeletion({
    required Passage passage,
    required int clauseIndex,
  }) {
    final segmentation = ClauseSegmentation.fromPassage(passage);

    // Validate clause index
    if (clauseIndex < 0 || clauseIndex >= segmentation.clauseCount) {
      throw ArgumentError(
        'clauseIndex $clauseIndex out of range (0-${segmentation.clauseCount - 1})',
      );
    }

    final clause = segmentation.clauses[clauseIndex];
    final hiddenIndices = Set<int>.from(clause.wordIndices);

    return ClozeOcclusion._(
      passage: passage,
      segmentation: segmentation,
      round: ClozeRound.rotatingClauseDeletion,
      hiddenIndices: hiddenIndices,
      hiddenClauseIndex: clauseIndex,
    );
  }

  /// Creates Round 3: First-2-words scaffolding.
  ///
  /// Shows only the first 2 words of every clause, hiding all others.
  /// This tests structural recall of the passage.
  factory ClozeOcclusion.firstTwoWordsScaffolding({required Passage passage}) {
    final segmentation = ClauseSegmentation.fromPassage(passage);
    final hiddenIndices = <int>{};

    // For each clause, hide everything except the first 2 words
    for (final clause in segmentation.clauses) {
      if (clause.wordCount <= 2) {
        // If clause has 2 or fewer words, don't hide anything
        continue;
      }

      // Hide words from index 2 onwards (keep first 2 visible)
      for (int i = 2; i < clause.wordCount; i++) {
        hiddenIndices.add(clause.startIndex + i);
      }
    }

    return ClozeOcclusion._(
      passage: passage,
      segmentation: segmentation,
      round: ClozeRound.firstTwoWordsScaffolding,
      hiddenIndices: hiddenIndices,
    );
  }

  /// Creates a specific occlusion pattern (useful for Prompted Mode or testing).
  factory ClozeOcclusion.manual({
    required Passage passage,
    required Set<int> hiddenIndices,
    ClozeRound round = ClozeRound.randomWordPerClause, // Default dummy round
  }) {
    // Generate segmentation just to fulfill the field requirement
    final segmentation = ClauseSegmentation.fromPassage(passage);

    return ClozeOcclusion._(
      passage: passage,
      segmentation: segmentation,
      round: round,
      hiddenIndices: hiddenIndices,
    );
  }

  /// Returns indices of "content words" in a clause (not trivial function words).
  ///
  /// Filters out common function words like: the, a, an, and, or, but, etc.
  /// These are less useful for testing recall.
  static List<int> _getContentWordIndices(Clause clause, Passage passage) {
    const trivialWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'of',
      'for',
      'with',
      'as',
      'by',
      'from',
      'is',
      'are',
      'was',
      'were',
    };

    final contentIndices = <int>[];

    for (int i = 0; i < clause.wordCount; i++) {
      final wordIndex = clause.startIndex + i;
      final word = passage.words[wordIndex].toLowerCase();

      // Remove punctuation for comparison
      final cleanWord = word.replaceAll(
        RegExp(r'[\p{P}\p{S}]', unicode: true),
        '',
      );

      if (cleanWord.isNotEmpty && !trivialWords.contains(cleanWord)) {
        contentIndices.add(wordIndex);
      }
    }

    return contentIndices;
  }

  /// Creates a copy with specific indices unhidden (revealed).
  ClozeOcclusion revealIndices(Set<int> indicesToReveal) {
    if (indicesToReveal.isEmpty) return this;

    final newHidden = Set<int>.from(hiddenIndices)..removeAll(indicesToReveal);

    return ClozeOcclusion._(
      passage: passage,
      segmentation: segmentation,
      round: round,
      hiddenIndices: newHidden,
      hiddenClauseIndex: hiddenClauseIndex,
    );
  }

  /// Checks if the word at [index] should be hidden.
  bool isWordHidden(int index) {
    return hiddenIndices.contains(index);
  }

  /// Returns the display word at [index] (hidden words show as underscores).
  ///
  /// Preserves "outer" punctuation (.,?! etc.) but hides the inner word content.
  String getDisplayWord(int index) {
    if (index < 0 || index >= passage.words.length) {
      throw RangeError(
        'Index $index out of range for passage with ${passage.words.length} words',
      );
    }

    final originalWord = passage.words[index];

    if (isWordHidden(index)) {
      final parts = parseWordParts(originalWord);

      // If no content (all punctuation), just return as is (or handle gracefully)
      if (parts.content.isEmpty) {
        return originalWord;
      }

      return '${parts.prefix}${'_' * parts.content.length}${parts.suffix}';
    }

    return originalWord;
  }

  /// Returns the length of the "inner" word content (excluding outer punctuation).
  ///
  /// This is the length the user is expected to type.
  int getMatchingLength(int index) {
    if (index < 0 || index >= passage.words.length) return 0;

    final originalWord = passage.words[index];
    final parts = parseWordParts(originalWord);
    return parts.content.length;
  }

  /// Splits a word into prefix (punctuation), content (inner word), and suffix (punctuation).
  static ({String prefix, String content, String suffix}) parseWordParts(
    String word,
  ) {
    // Matches any letter or number (unicode aware)
    final alphaNum = RegExp(r'[\p{L}\p{N}]', unicode: true);
    final startIndex = word.indexOf(alphaNum);

    if (startIndex == -1) {
      // No alphanumeric characters (e.g. "...")
      return (prefix: word, content: '', suffix: '');
    }

    final endIndex = word.lastIndexOf(alphaNum);

    final prefix = word.substring(0, startIndex);
    final content = word.substring(startIndex, endIndex + 1);
    final suffix = word.substring(endIndex + 1);

    return (prefix: prefix, content: content, suffix: suffix);
  }

  /// Returns the full display text with hidden words as underscores.
  String getDisplayText() {
    final displayWords = <String>[];
    for (int i = 0; i < passage.words.length; i++) {
      displayWords.add(getDisplayWord(i));
    }
    return displayWords.join(' ');
  }

  /// The index of the first hidden word (in sequential order).
  int? get firstHiddenIndex {
    if (hiddenIndices.isEmpty) return null;
    return hiddenIndices.reduce(min);
  }

  /// Checks if the input matches the word at [index].
  ///
  /// Accepts exact matches and close typos (Levenshtein distance <= 1).
  bool checkWord(int index, String input, {int maxDistance = 1}) {
    if (!hiddenIndices.contains(index)) return false;

    final hiddenWord = _cleanWord(passage.words[index]);
    final cleanInput = _cleanWord(input);

    if (hiddenWord.isEmpty) return false;

    // Exact match
    if (hiddenWord == cleanInput) return true;

    // Typo tolerance: allow small Levenshtein distance
    // Only apply if lengths are close (prevents accepting completely wrong words)
    if ((cleanInput.length - hiddenWord.length).abs() <= 1) {
      final distance = _levenshtein(hiddenWord, cleanInput);
      if (distance > maxDistance) {
        debugPrint(
          'Validation Failed: Expected="$hiddenWord" (${passage.words[index]}), '
          'Received="$cleanInput" ($input), Distance=$distance (Max=$maxDistance)',
        );
      }
      return distance <= maxDistance;
    }

    debugPrint(
      'Validation Failed: Expected="$hiddenWord" (${passage.words[index]}), '
      'Received="$cleanInput" ($input), Length Mismatch',
    );
    return false;
  }

  String _cleanWord(String word) {
    // Strip punctuation and symbols, preserve letters and numbers.
    return word
        .replaceAll(RegExp(r'[\p{P}\p{S}]', unicode: true), '')
        .toLowerCase();
  }

  /// Calculates Levenshtein edit distance between two strings.
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  /// Returns the percentage of words that are visible (0.0 to 1.0).
  double get visibleRatio {
    if (passage.words.isEmpty) return 1.0;
    final visibleCount = passage.words.length - hiddenIndices.length;
    return visibleCount / passage.words.length;
  }

  /// Number of currently hidden words.
  int get hiddenWordCount => hiddenIndices.length;

  /// Total number of words in the passage.
  int get totalWordCount => passage.words.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClozeOcclusion &&
        other.passage == passage &&
        other.round == round &&
        other.hiddenIndices.length == hiddenIndices.length &&
        other.hiddenIndices.every((i) => hiddenIndices.contains(i)) &&
        other.hiddenClauseIndex == hiddenClauseIndex;
  }

  @override
  int get hashCode {
    return Object.hash(passage, round, hiddenIndices.length, hiddenClauseIndex);
  }

  @override
  String toString() {
    return 'ClozeOcclusion(round: $round, hidden: $hiddenWordCount/$totalWordCount)';
  }
}
