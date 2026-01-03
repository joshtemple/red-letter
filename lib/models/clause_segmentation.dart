import 'package:red_letter/models/passage.dart';

/// Represents a single clause within a passage.
///
/// A clause is a meaningful segment of text, typically bounded by punctuation
/// or explicit line breaks. Used for the Advanced Acquisition Ladder's
/// clause-based scaffolding modes.
class Clause {
  /// The word indices that belong to this clause (inclusive range)
  final int startIndex;
  final int endIndex;

  /// The actual words in this clause
  final List<String> words;

  /// The clause text (for display/debugging)
  final String text;

  const Clause({
    required this.startIndex,
    required this.endIndex,
    required this.words,
    required this.text,
  });

  /// Number of words in this clause
  int get wordCount => words.length;

  /// Checks if a word index belongs to this clause
  bool containsWordIndex(int index) {
    return index >= startIndex && index <= endIndex;
  }

  /// Returns all word indices in this clause
  List<int> get wordIndices {
    return List.generate(
      wordCount,
      (i) => startIndex + i,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Clause &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(startIndex, endIndex, text);

  @override
  String toString() {
    return 'Clause(${startIndex}-${endIndex}: "$text")';
  }
}

/// Manages clause segmentation for a passage.
///
/// Splits passage text into meaningful clauses based on:
/// - Punctuation (.,:;!?)
/// - Explicit line breaks
/// - Logical breaks in the text
///
/// This enables clause-based scaffolding modes in the acquisition ladder.
class ClauseSegmentation {
  final Passage passage;
  final List<Clause> clauses;

  ClauseSegmentation._({
    required this.passage,
    required this.clauses,
  });

  /// Creates clause segmentation for a passage.
  ///
  /// Segments based on:
  /// - Major punctuation: . ! ? (end of sentence)
  /// - Minor punctuation: , : ; (clause breaks)
  /// - Explicit newlines in the original text
  factory ClauseSegmentation.fromPassage(Passage passage) {
    final clauses = _segmentIntoClauses(passage);

    return ClauseSegmentation._(
      passage: passage,
      clauses: clauses,
    );
  }

  /// Segments the passage into clauses based on punctuation.
  static List<Clause> _segmentIntoClauses(Passage passage) {
    if (passage.words.isEmpty) return [];

    final clauses = <Clause>[];
    int clauseStart = 0;

    for (int i = 0; i < passage.words.length; i++) {
      final word = passage.words[i];
      final isClauseBreak = _isClauseBreakPoint(word);

      // If we hit a clause break or the last word, close the current clause
      if (isClauseBreak || i == passage.words.length - 1) {
        final clauseEnd = i;

        // Extract words for this clause
        final clauseWords = passage.words.sublist(
          clauseStart,
          clauseEnd + 1,
        );

        // Build clause text
        final clauseText = clauseWords.join(' ');

        clauses.add(Clause(
          startIndex: clauseStart,
          endIndex: clauseEnd,
          words: clauseWords,
          text: clauseText,
        ));

        // Start next clause after this break point
        clauseStart = i + 1;
      }
    }

    // If we have leftover words (shouldn't happen with the logic above, but safety check)
    if (clauseStart < passage.words.length) {
      final clauseWords = passage.words.sublist(clauseStart);
      clauses.add(Clause(
        startIndex: clauseStart,
        endIndex: passage.words.length - 1,
        words: clauseWords,
        text: clauseWords.join(' '),
      ));
    }

    return clauses;
  }

  /// Determines if a word ends with clause-breaking punctuation.
  ///
  /// Major breaks: . ! ?
  /// Minor breaks: , : ;
  static bool _isClauseBreakPoint(String word) {
    if (word.isEmpty) return false;

    final lastChar = word[word.length - 1];
    return lastChar == '.' ||
        lastChar == ',' ||
        lastChar == ':' ||
        lastChar == ';' ||
        lastChar == '!' ||
        lastChar == '?';
  }

  /// Returns the clause that contains the given word index.
  Clause? getClauseForWordIndex(int wordIndex) {
    for (final clause in clauses) {
      if (clause.containsWordIndex(wordIndex)) {
        return clause;
      }
    }
    return null;
  }

  /// Returns the clause at the specified clause index.
  Clause? getClauseAt(int clauseIndex) {
    if (clauseIndex < 0 || clauseIndex >= clauses.length) {
      return null;
    }
    return clauses[clauseIndex];
  }

  /// Total number of clauses in this passage.
  int get clauseCount => clauses.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClauseSegmentation &&
        other.passage == passage &&
        other.clauses.length == clauses.length;
  }

  @override
  int get hashCode => Object.hash(passage, clauses.length);

  @override
  String toString() {
    return 'ClauseSegmentation(${clauses.length} clauses for ${passage.reference})';
  }
}
