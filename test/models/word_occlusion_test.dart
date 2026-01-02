import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/word_occlusion.dart';

void main() {
  group('WordOcclusion', () {
    late Passage testPassage;

    setUp(() {
      testPassage = Passage.fromText(
        id: 'mat-5-44',
        text: 'Love your enemies and pray for those who persecute you',
        reference: 'Matthew 5:44',
      );
    });

    test('should generate occlusion with default ratio (30-50%)', () {
      final occlusion = WordOcclusion.generate(passage: testPassage);

      expect(occlusion.passage, testPassage);
      expect(occlusion.totalWordCount, testPassage.words.length);
      expect(occlusion.hiddenWordCount, greaterThanOrEqualTo(3)); // ~30% of 10 words
      expect(occlusion.hiddenWordCount, lessThanOrEqualTo(5)); // ~50% of 10 words
      expect(occlusion.occlusionRatio, greaterThanOrEqualTo(0.3));
      expect(occlusion.occlusionRatio, lessThanOrEqualTo(0.5));
    });

    test('should generate occlusion with custom ratio', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        minRatio: 0.2,
        maxRatio: 0.3,
      );

      expect(occlusion.hiddenWordCount, greaterThanOrEqualTo(2)); // ~20% of 10 words
      expect(occlusion.hiddenWordCount, lessThanOrEqualTo(3)); // ~30% of 10 words
    });

    test('should generate reproducible patterns with same seed', () {
      final occlusion1 = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );
      final occlusion2 = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      expect(occlusion1.hiddenIndices, occlusion2.hiddenIndices);
      expect(occlusion1.occlusionRatio, occlusion2.occlusionRatio);
      expect(occlusion1.getDisplayText(), occlusion2.getDisplayText());
    });

    test('should generate different patterns with different seeds', () {
      final occlusion1 = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );
      final occlusion2 = WordOcclusion.generate(
        passage: testPassage,
        seed: 99,
      );

      expect(occlusion1.hiddenIndices, isNot(equals(occlusion2.hiddenIndices)));
    });

    test('should generate different patterns without seed', () {
      final patterns = <Set<int>>[];
      for (int i = 0; i < 10; i++) {
        final occlusion = WordOcclusion.generate(passage: testPassage);
        patterns.add(occlusion.hiddenIndices);
      }

      // At least some patterns should be different
      final uniquePatterns = patterns.toSet();
      expect(uniquePatterns.length, greaterThan(1));
    });

    test('should correctly identify hidden words', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      for (int i = 0; i < testPassage.words.length; i++) {
        final isHidden = occlusion.isWordHidden(i);
        expect(isHidden, occlusion.hiddenIndices.contains(i));
      }
    });

    test('should return underscore placeholder for hidden words', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      for (int i = 0; i < testPassage.words.length; i++) {
        final displayWord = occlusion.getDisplayWord(i);
        if (occlusion.isWordHidden(i)) {
          expect(displayWord, '_' * testPassage.words[i].length);
        } else {
          expect(displayWord, testPassage.words[i]);
        }
      }
    });

    test('should return actual word for visible words', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      for (int i = 0; i < testPassage.words.length; i++) {
        if (!occlusion.isWordHidden(i)) {
          expect(occlusion.getDisplayWord(i), testPassage.words[i]);
        }
      }
    });

    test('should generate full display text with placeholders', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      final displayText = occlusion.getDisplayText();
      final words = displayText.split(' ');

      expect(words.length, testPassage.words.length);
      for (int i = 0; i < words.length; i++) {
        expect(words[i], occlusion.getDisplayWord(i));
      }
    });

    test('should count hidden and visible words correctly', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      expect(
        occlusion.hiddenWordCount + occlusion.visibleWordCount,
        occlusion.totalWordCount,
      );
      expect(occlusion.totalWordCount, testPassage.words.length);
    });

    test('should throw RangeError for invalid index', () {
      final occlusion = WordOcclusion.generate(passage: testPassage);

      expect(() => occlusion.getDisplayWord(-1), throwsRangeError);
      expect(() => occlusion.getDisplayWord(100), throwsRangeError);
    });

    test('should handle minimum occlusion (0%)', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        minRatio: 0.0,
        maxRatio: 0.0,
      );

      expect(occlusion.hiddenWordCount, 0);
      expect(occlusion.getDisplayText(), testPassage.text);
    });

    test('should handle maximum occlusion (100%)', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        minRatio: 1.0,
        maxRatio: 1.0,
      );

      expect(occlusion.hiddenWordCount, testPassage.words.length);
      final displayText = occlusion.getDisplayText();
      expect(displayText, isNot(contains(testPassage.words[0])));
    });

    test('should handle single word passage', () {
      final singleWord = Passage.fromText(
        id: 'test',
        text: 'Love',
        reference: 'Test 1:1',
      );
      final occlusion = WordOcclusion.generate(
        passage: singleWord,
        minRatio: 0.5,
        maxRatio: 0.5,
      );

      expect(occlusion.totalWordCount, 1);
      expect(occlusion.hiddenWordCount, lessThanOrEqualTo(1));
    });

    test('should maintain underscore length matching word length', () {
      final occlusion = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );

      for (int i = 0; i < testPassage.words.length; i++) {
        if (occlusion.isWordHidden(i)) {
          final displayWord = occlusion.getDisplayWord(i);
          final originalWord = testPassage.words[i];
          expect(displayWord.length, originalWord.length);
          expect(displayWord, '_' * originalWord.length);
        }
      }
    });

    test('should support equality comparison', () {
      final occlusion1 = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );
      final occlusion2 = WordOcclusion.generate(
        passage: testPassage,
        seed: 42,
      );
      final occlusion3 = WordOcclusion.generate(
        passage: testPassage,
        seed: 99,
      );

      expect(occlusion1, equals(occlusion2));
      expect(occlusion1, isNot(equals(occlusion3)));
    });

    test('should assert valid ratio ranges', () {
      expect(
        () => WordOcclusion.generate(
          passage: testPassage,
          minRatio: -0.1,
        ),
        throwsAssertionError,
      );

      expect(
        () => WordOcclusion.generate(
          passage: testPassage,
          maxRatio: 1.5,
        ),
        throwsAssertionError,
      );

      expect(
        () => WordOcclusion.generate(
          passage: testPassage,
          minRatio: 0.6,
          maxRatio: 0.4,
        ),
        throwsAssertionError,
      );
    });

    test('should handle passage with punctuation in words', () {
      final punctuatedPassage = Passage.fromText(
        id: 'test',
        text: "Don't worry, be happy!",
        reference: 'Test 1:1',
      );
      final occlusion = WordOcclusion.generate(
        passage: punctuatedPassage,
        seed: 42,
      );

      expect(occlusion.totalWordCount, punctuatedPassage.words.length);
      for (int i = 0; i < punctuatedPassage.words.length; i++) {
        if (occlusion.isWordHidden(i)) {
          final displayWord = occlusion.getDisplayWord(i);
          expect(displayWord.length, punctuatedPassage.words[i].length);
        }
      }
    });
  });
}
