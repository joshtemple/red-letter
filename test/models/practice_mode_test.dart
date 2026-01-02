import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/practice_mode.dart';

void main() {
  group('PracticeMode', () {
    test('should have correct display names', () {
      expect(PracticeMode.impression.displayName, 'Impression');
      expect(PracticeMode.reflection.displayName, 'Reflection');
      expect(PracticeMode.scaffolding.displayName, 'Scaffolding');
      expect(PracticeMode.prompted.displayName, 'Prompted');
      expect(PracticeMode.reconstruction.displayName, 'Reconstruction');
    });

    test('should have correct descriptions', () {
      expect(PracticeMode.impression.description,
          'Full text + visual mnemonic display');
      expect(PracticeMode.reflection.description,
          'Mandatory reflection prompt (semantic encoding)');
      expect(PracticeMode.scaffolding.description,
          'Variable ratio occlusion (random words hidden)');
      expect(PracticeMode.prompted.description,
          'Blank input with sparse prompting');
      expect(PracticeMode.reconstruction.description,
          'Total independent recall');
    });

    test('should progress through modes in correct order', () {
      expect(PracticeMode.impression.next, PracticeMode.reflection);
      expect(PracticeMode.reflection.next, PracticeMode.scaffolding);
      expect(PracticeMode.scaffolding.next, PracticeMode.prompted);
      expect(PracticeMode.prompted.next, PracticeMode.reconstruction);
      expect(PracticeMode.reconstruction.next, null);
    });

    test('should have 5 total modes', () {
      expect(PracticeMode.values.length, 5);
    });
  });
}
