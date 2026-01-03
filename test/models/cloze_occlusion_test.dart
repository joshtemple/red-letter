import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/models/passage.dart';

void main() {
  group('ClozeOcclusion - Round 1: Random Word Per Clause', () {
    test('hides content words from each clause', () {
      final passage = Passage.fromText(
        id: 'test-1',
        text: 'Love your enemies, bless those who curse you.',
        reference: 'Test 1:1',
      );

      final occlusion = ClozeOcclusion.randomWordPerClause(
        passage: passage,
        wordsPerClause: 1,
        seed: 42, // Deterministic for testing
      );

      expect(occlusion.round, ClozeRound.randomWordPerClause);
      expect(occlusion.hiddenWordCount, greaterThan(0));

      // Should have hidden words, but not all
      expect(occlusion.visibleRatio, lessThan(1.0));
      expect(occlusion.visibleRatio, greaterThan(0.5));
    });

    test('skips trivial words when selecting words to hide', () {
      final passage = Passage.fromText(
        id: 'test-2',
        text: 'Love the enemies, bless the people.',
        reference: 'Test 2:1',
      );

      final occlusion = ClozeOcclusion.randomWordPerClause(
        passage: passage,
        wordsPerClause: 1,
        seed: 42,
      );

      // Check that "the" is not hidden (it's a trivial word)
      final theIndices = <int>[];
      for (int i = 0; i < passage.words.length; i++) {
        if (passage.words[i].toLowerCase() == 'the') {
          theIndices.add(i);
        }
      }

      for (final index in theIndices) {
        expect(occlusion.isWordHidden(index), false);
      }
    });
  });

  group('ClozeOcclusion - Round 2: Rotating Clause Deletion', () {
    test('hides entire clause when specified', () {
      final passage = Passage.fromText(
        id: 'test-3',
        text: 'First clause, second clause.',
        reference: 'Test 3:1',
      );

      final occlusion = ClozeOcclusion.rotatingClauseDeletion(
        passage: passage,
        clauseIndex: 0,
      );

      expect(occlusion.round, ClozeRound.rotatingClauseDeletion);
      expect(occlusion.hiddenClauseIndex, 0);

      // First clause should be completely hidden
      // "First clause,"
      expect(occlusion.isWordHidden(0), true); // "First"
      expect(occlusion.isWordHidden(1), true); // "clause,"

      // Second clause should be visible
      // "second clause."
      expect(occlusion.isWordHidden(2), false); // "second"
      expect(occlusion.isWordHidden(3), false); // "clause."
    });

    test('can rotate to hide different clauses', () {
      final passage = Passage.fromText(
        id: 'test-4',
        text: 'One, two, three.',
        reference: 'Test 4:1',
      );

      // Hide clause 1 (middle clause)
      final occlusion = ClozeOcclusion.rotatingClauseDeletion(
        passage: passage,
        clauseIndex: 1,
      );

      expect(occlusion.isWordHidden(0), false); // "One,"
      expect(occlusion.isWordHidden(1), true); // "two,"
      expect(occlusion.isWordHidden(2), false); // "three."
    });

    test('throws on invalid clause index', () {
      final passage = Passage.fromText(
        id: 'test-5',
        text: 'One, two.',
        reference: 'Test 5:1',
      );

      expect(
        () => ClozeOcclusion.rotatingClauseDeletion(
          passage: passage,
          clauseIndex: 99, // Out of range
        ),
        throwsArgumentError,
      );
    });
  });

  group('ClozeOcclusion - Round 3: First Two Words Scaffolding', () {
    test('shows only first 2 words of each clause', () {
      final passage = Passage.fromText(
        id: 'test-6',
        text: 'Love your enemies and bless them, pray for your persecutors.',
        reference: 'Test 6:1',
      );

      final occlusion = ClozeOcclusion.firstTwoWordsScaffolding(
        passage: passage,
      );

      expect(occlusion.round, ClozeRound.firstTwoWordsScaffolding);

      // First clause: "Love your enemies and bless them,"
      // Should show "Love your" and hide the rest
      expect(occlusion.isWordHidden(0), false); // "Love"
      expect(occlusion.isWordHidden(1), false); // "your"
      expect(occlusion.isWordHidden(2), true); // "enemies"
      expect(occlusion.isWordHidden(3), true); // "and"
      expect(occlusion.isWordHidden(4), true); // "bless"
      expect(occlusion.isWordHidden(5), true); // "them,"

      // Second clause: "pray for your persecutors."
      // Should show "pray for" and hide the rest
      expect(occlusion.isWordHidden(6), false); // "pray"
      expect(occlusion.isWordHidden(7), false); // "for"
      expect(occlusion.isWordHidden(8), true); // "your"
      expect(occlusion.isWordHidden(9), true); // "persecutors."
    });

    test('handles short clauses (2 words or less)', () {
      final passage = Passage.fromText(
        id: 'test-7',
        text: 'Go, do it.',
        reference: 'Test 7:1',
      );

      final occlusion = ClozeOcclusion.firstTwoWordsScaffolding(
        passage: passage,
      );

      // "Go," is only 1 word, so nothing should be hidden
      expect(occlusion.isWordHidden(0), false); // "Go,"

      // "do it." is 2 words, so nothing should be hidden
      expect(occlusion.isWordHidden(1), false); // "do"
      expect(occlusion.isWordHidden(2), false); // "it."
    });
  });

  group('ClozeOcclusion - Common Functionality', () {
    test('getDisplayText shows underscores for hidden words', () {
      final passage = Passage.fromText(
        id: 'test-8',
        text: 'Love your enemies.',
        reference: 'Test 8:1',
      );

      final occlusion = ClozeOcclusion.randomWordPerClause(
        passage: passage,
        wordsPerClause: 1,
        seed: 42,
      );

      final displayText = occlusion.getDisplayText();

      // Should contain some underscores
      expect(displayText.contains('_'), true);

      // Should preserve word lengths
      for (int i = 0; i < passage.words.length; i++) {
        if (occlusion.isWordHidden(i)) {
          final originalLength = passage.words[i].length;
          final underscores = '_' * originalLength;
          expect(displayText.contains(underscores), true);
        }
      }
    });

    test('revealIndices unhides specified words', () {
      final passage = Passage.fromText(
        id: 'test-9',
        text: 'One two three.',
        reference: 'Test 9:1',
      );

      final occlusion = ClozeOcclusion.randomWordPerClause(
        passage: passage,
        seed: 42,
      );

      final originalHiddenCount = occlusion.hiddenWordCount;

      // Reveal the first hidden word
      final firstHidden = occlusion.firstHiddenIndex;
      if (firstHidden != null) {
        final revealed = occlusion.revealIndices({firstHidden});

        expect(revealed.hiddenWordCount, originalHiddenCount - 1);
        expect(revealed.isWordHidden(firstHidden), false);
      }
    });

    test('checkWord validates input correctly', () {
      final passage = Passage.fromText(
        id: 'test-10',
        text: 'Test word.',
        reference: 'Test 10:1',
      );

      final occlusion = ClozeOcclusion.randomWordPerClause(
        passage: passage,
        seed: 42,
      );

      final firstHidden = occlusion.firstHiddenIndex;
      if (firstHidden != null) {
        final hiddenWord = passage.words[firstHidden];
        final cleanWord = hiddenWord.replaceAll(RegExp(r'[^\w]'), '');

        expect(occlusion.checkWord(firstHidden, cleanWord), true);
        expect(occlusion.checkWord(firstHidden, 'wrong'), false);
      }
    });

    test('visibleRatio calculates correctly', () {
      final passage = Passage.fromText(
        id: 'test-11',
        text: 'One two three four.',
        reference: 'Test 11:1',
      );

      // Hide entire passage
      final occlusion = ClozeOcclusion.rotatingClauseDeletion(
        passage: passage,
        clauseIndex: 0,
      );

      expect(occlusion.visibleRatio, 0.0);

      // Reveal all words
      final revealed = occlusion.revealIndices(occlusion.hiddenIndices);
      expect(revealed.visibleRatio, 1.0);
    });
  });
}
