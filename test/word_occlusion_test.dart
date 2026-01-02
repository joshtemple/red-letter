import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/word_occlusion.dart';

void main() {
  group('WordOcclusion Logic', () {
    late Passage passage;
    late WordOcclusion occlusion;

    setUp(() {
      passage = Passage.fromText(
        id: '1',
        text: 'Jesus wept.',
        reference: 'John 11:35',
      );
      occlusion = WordOcclusion.manual(
        passage: passage,
        hiddenIndices: {0, 1}, // Hide 'Jesus' and 'wept.'
      );
    });

    test('should reveal exact match', () {
      final result = occlusion.checkInput('Jesus');
      expect(result.isWordHidden(0), false);
      expect(result.isWordHidden(1), true);
    });

    test('should reveal match with punctuation difference', () {
      // Hidden word is 'wept.'
      // Input is 'wept' (no dot)
      // Logic should strip dot from hidden word and compare
      final result = occlusion.checkInput('wept');
      expect(result.isWordHidden(1), false);
    });

    test('should match case insensitive', () {
      final result = occlusion.checkInput('jesus');
      expect(result.isWordHidden(0), false);
    });

    test('should reveal multiple words if present in input', () {
      final result = occlusion.checkInput('Jesus wept');
      expect(result.isWordHidden(0), false);
      expect(result.isWordHidden(1), false);
    });

    test('should not reveal incorrect match', () {
      final result = occlusion.checkInput('Peter');
      expect(result.isWordHidden(0), true);
      expect(result.isWordHidden(1), true);
    });

    test('should calculate completion percentage', () {
      // Initial: 2 words, 2 hidden. Visible = 0.
      expect(occlusion.visibleRatio, 0.0);

      // Reveal 1
      final partial = occlusion.checkInput('Jesus');
      expect(partial.visibleRatio, 0.5);

      // Reveal remaining
      final full = partial.checkInput('wept');
      expect(full.visibleRatio, 1.0);
    });
  });
}
