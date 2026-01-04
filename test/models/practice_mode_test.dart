import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/practice_mode.dart';

void main() {
  group('PracticeMode', () {
    test('should have correct display names', () {
      expect(PracticeMode.impression.displayName, 'Impression');
      expect(PracticeMode.reflection.displayName, 'Reflection');
      expect(PracticeMode.randomWords.displayName, 'Cloze: Random Words');
      expect(
        PracticeMode.rotatingClauses.displayName,
        'Cloze: Missing Clauses',
      );
      expect(PracticeMode.firstTwoWords.displayName, 'Cloze: First Two Words');
      expect(PracticeMode.prompted.displayName, 'Prompted');
      expect(PracticeMode.reconstruction.displayName, 'Reconstruction');
    });

    test('should have correct descriptions', () {
      expect(
        PracticeMode.impression.description,
        'Full text + visual mnemonic display',
      );
      expect(
        PracticeMode.reflection.description,
        'Mandatory reflection prompt (semantic encoding)',
      );
      expect(
        PracticeMode.randomWords.description,
        '1-2 random non-trivial words removed per clause',
      );
      expect(
        PracticeMode.rotatingClauses.description,
        'One entire clause hidden (rotating)',
      );
      expect(
        PracticeMode.firstTwoWords.description,
        'Only the first 2 words of each clause shown',
      );
    });

    test('should progress through modes in correct order', () {
      expect(PracticeMode.impression.next, PracticeMode.reflection);
      expect(PracticeMode.reflection.next, PracticeMode.randomWords);
      expect(PracticeMode.randomWords.next, PracticeMode.rotatingClauses);
      expect(PracticeMode.rotatingClauses.next, PracticeMode.firstTwoWords);
      expect(PracticeMode.firstTwoWords.next, PracticeMode.prompted);
      expect(PracticeMode.prompted.next, PracticeMode.reconstruction);
      expect(PracticeMode.reconstruction.next, null);
    });

    test('should have 7 total modes', () {
      expect(PracticeMode.values.length, 7);
    });
  });
}
