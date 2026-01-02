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

  static String _normalizeLenient(String text) {
    // Remove punctuation, keep alphanumeric, collapse whitespace, lowercase
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
