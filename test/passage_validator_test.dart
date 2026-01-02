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

    test('isStrictMatch respects punctuation', () {
      // "Strict" as defined: Case-insensitive, Punctuation-sensitive
      expect(PassageValidator.isStrictMatch(target, 'Jesus wept.'), isTrue);
      expect(PassageValidator.isStrictMatch(target, 'jesus wept.'), isTrue);

      expect(
        PassageValidator.isStrictMatch(target, 'Jesus wept'),
        isFalse,
      ); // Missing dot
      expect(
        PassageValidator.isStrictMatch(target, 'Jesus, wept.'),
        isFalse,
      ); // Extra comma
    });
  });
}
