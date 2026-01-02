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
  /// Ignores case but respects punctuation (mostly).
  /// Actually, for "Reconstruction", maybe we want exact punctuation?
  /// Let's define "Strict" as case-insensitive but punctuation-sensitive?
  /// Or exact match?
  /// User requirement: "Typing validation: Must execute within 8-16ms".
  /// "Reconstruction Mode - Total independent recall".
  /// Usually memorization apps match strictly on words, but case is often forgiven. Punctuation is mixed.
  /// Let's define Strict as: Case-insensitive, Punctuation-sensitive.
  static bool isStrictMatch(String target, String input) {
    if (input.isEmpty) return false;
    return target.trim().toLowerCase() == input.trim().toLowerCase();
  }

  /// Checks if the input is a valid prefix of the target.
  static bool isValidPrefix(String target, String input) {
    if (input.isEmpty) return true;
    // We use a prefix-friendly normalization (don't trim end of input to allow space check?)
    // Actually, _normalizeLenient trims.
    // If input is "Love ", normalized is "love". "love" is prefix of "love your".
    // But "Love x" -> "love x". Not prefix.
    // Issue: "Love " matches "Love". User thinks they are done with word.
    // If we want detailed prefix check, we should retain spaces in input normalization if in middle?
    // _normalizeLenient replaces \s+ with ' '.
    final nTarget = _normalizeLenient(target);
    final nInput = _normalizeLenient(input);
    return nTarget.startsWith(nInput);
  }

  /// Returns the next word from the target that follows the input.
  static String getNextHint(String target, String input) {
    // Simple implementation: split target, see how many words input covers.
    // This is tricky with fuzzy matching.
    // A robust way: find the length of the matching prefix in target?
    // Or just normalization.

    final nTarget = _normalizeLenient(target);
    final nInput = _normalizeLenient(input);

    if (!nTarget.startsWith(nInput)) {
      // Input is wrong, provide hint for start?
      // Or first word.
      final words = nTarget.split(' ');
      return words.isNotEmpty ? words.first : '';
    }

    // Input matches.
    // Example: Target "love your enemies"
    // Input "love" -> nInput "love".
    // Remaining: " your enemies".
    // Next word: "your".

    final remaining = nTarget.substring(nInput.length).trimLeft();
    final words = remaining.split(' ');
    if (words.isEmpty || (words.length == 1 && words.first.isEmpty)) {
      return '';
    }
    return words.first;
  }

  static String _normalizeLenient(String text) {
    // Remove punctuation, keep alphanumeric, collapse whitespace, lowercase
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
