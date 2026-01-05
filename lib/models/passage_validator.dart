class PassageValidator {
  PassageValidator._();

  /// specific normalization rules can be added here

  /// Checks if the input matches the target text leniently.
  /// Ignores case and punctuation.
  static bool isLenientMatch(String target, String input) {
    if (input.isEmpty) return false;
    return _normalizeLenient(target) == _normalizeLenient(input);
  }

  /// Checks if the input matches the target text strictly.
  /// Compares based on words only - ignores case, punctuation, and extra whitespace.
  /// Uses the same robust validation as ClozeOcclusion (Levenshtein distance <= 1).
  static bool isStrictMatch(String target, String input) {
    if (input.isEmpty) return false;

    // Tokenize target and input into words
    final targetWords = _tokenize(target);
    final inputWords = _tokenize(input);

    if (targetWords.length != inputWords.length) {
      // debugPrint(
      //   'PassageValidator Failed: Word count mismatch. Expected=${targetWords.length}, Received=${inputWords.length}',
      // );
      return false;
    }

    for (int i = 0; i < targetWords.length; i++) {
      if (!isWordMatch(targetWords[i], inputWords[i])) {
        // debugPrint(
        //   'PassageValidator Failed at word $i: Expected="${targetWords[i]}", Received="${inputWords[i]}"',
        // );
        return false;
      }
    }

    return true;
  }

  /// Checks if two words match strictly (clean + levenshtein).
  static bool isWordMatch(
    String targetWord,
    String inputWord, {
    int maxDistance = 1,
  }) {
    final cleanTarget = cleanWord(targetWord);
    final cleanInput = cleanWord(inputWord);

    if (cleanTarget.isEmpty) return false; // Should not happen with _tokenize

    // Exact match
    if (cleanTarget == cleanInput) return true;

    // Typo tolerance
    if ((cleanInput.length - cleanTarget.length).abs() <= 1) {
      final distance = levenshtein(cleanTarget, cleanInput);
      return distance <= maxDistance;
    }

    return false;
  }

  /// Checks if the input is close enough to the target to be considered a potentially recoverable typo (retry).
  /// Uses a threshold of 1 for words <= 3 length, and 2 for longer words.
  static bool isTypoRetry(String target, String input) {
    final cleanTarget = cleanWord(target);
    final cleanInput = cleanWord(input);

    final distance = levenshtein(cleanInput, cleanTarget);
    final threshold = cleanTarget.length <= 3 ? 1 : 2;

    return distance <= threshold;
  }

  /// Tokenizes text into words, removing empty ones.
  static List<String> _tokenize(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// Checks if the input is a valid prefix of the target.
  static bool isValidPrefix(String target, String input) {
    if (input.isEmpty) return true;
    // Prefix check using normalized strings
    final nTarget = _normalizeLenient(target);
    final nInput = _normalizeLenient(input);
    return nTarget.startsWith(nInput);
  }

  /// Returns the next word from the target that follows the input.
  static String getNextHint(String target, String input) {
    final nTarget = _normalizeLenient(target);
    final nInput = _normalizeLenient(input);

    if (!nTarget.startsWith(nInput)) {
      final words = nTarget.split(' ');
      return words.isNotEmpty ? words.first : '';
    }

    final remaining = nTarget.substring(nInput.length).trimLeft();
    final words = remaining.split(' ');
    if (words.isEmpty || (words.length == 1 && words.first.isEmpty)) {
      return '';
    }
    return words.first;
  }

  static String _normalizeLenient(String text) {
    // Remove punctuation, keep alphanumeric, collapse whitespace, lowercase
    return cleanWord(text).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Cleans a string by removing punctuation and symbols, and converting to lowercase.
  static String cleanWord(String word) {
    return word
        .replaceAll(RegExp(r'[\p{P}\p{S}]', unicode: true), '')
        .toLowerCase();
  }

  /// Calculates Levenshtein edit distance between two strings.
  static int levenshtein(String s, String t) {
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
}
