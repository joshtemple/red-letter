import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage_validator.dart';

void main() {
  group('PassageValidator', () {
    const target = 'Jesus wept.';

    test('isLenientMatch ignores case and punctuation', () {
      expect(PassageValidator.isLenientMatch(target, 'Jesus wept'), isTrue);
      expect(PassageValidator.isLenientMatch(target, 'jesus wept'), isTrue);
      expect(PassageValidator.isLenientMatch(target, 'JESUS WEPT!'), isTrue);
      expect(PassageValidator.isLenientMatch(target, 'Jesus  wept'), isTrue);

      expect(PassageValidator.isLenientMatch(target, 'Jesus slept'), isFalse);
    });

    test('isStrictMatch ignores punctuation, case, and whitespace', () {
      // Word-based comparison - only the actual words matter
      expect(PassageValidator.isStrictMatch(target, 'Jesus wept.'), isTrue);
      expect(PassageValidator.isStrictMatch(target, 'jesus wept.'), isTrue);
      expect(PassageValidator.isStrictMatch(target, 'Jesus wept'), isTrue); // No punctuation is OK
      expect(PassageValidator.isStrictMatch(target, 'JESUS WEPT!'), isTrue); // Different punctuation is OK
      expect(PassageValidator.isStrictMatch(target, 'Jesus  wept'), isTrue); // Extra spaces are OK

      expect(
        PassageValidator.isStrictMatch(target, 'Jesus slept'),
        isFalse,
      ); // Different word
    });
  });
}
