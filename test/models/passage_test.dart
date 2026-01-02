import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';

void main() {
  group('Passage', () {
    const testId = 'mat-5-44';
    const testText = 'Love your enemies and pray for those who persecute you';
    const testReference = 'Matthew 5:44';

    test('should create passage from text with tokenization', () {
      final passage = Passage.fromText(
        id: testId,
        text: testText,
        reference: testReference,
      );

      expect(passage.id, testId);
      expect(passage.text, testText);
      expect(passage.reference, testReference);
      expect(passage.words, [
        'Love',
        'your',
        'enemies',
        'and',
        'pray',
        'for',
        'those',
        'who',
        'persecute',
        'you'
      ]);
    });

    test('should create passage from JSON', () {
      final json = {
        'id': testId,
        'text': testText,
        'reference': testReference,
        'words': ['Love', 'your', 'enemies']
      };

      final passage = Passage.fromJson(json);

      expect(passage.id, testId);
      expect(passage.text, testText);
      expect(passage.reference, testReference);
      expect(passage.words, ['Love', 'your', 'enemies']);
    });

    test('should convert passage to JSON', () {
      final passage = Passage.fromText(
        id: testId,
        text: testText,
        reference: testReference,
      );

      final json = passage.toJson();

      expect(json['id'], testId);
      expect(json['text'], testText);
      expect(json['reference'], testReference);
      expect(json['words'], isA<List<String>>());
    });

    test('should handle copyWith correctly', () {
      final passage = Passage.fromText(
        id: testId,
        text: testText,
        reference: testReference,
      );

      final copied = passage.copyWith(reference: 'Matthew 5:44-45');

      expect(copied.id, testId);
      expect(copied.text, testText);
      expect(copied.reference, 'Matthew 5:44-45');
    });

    test('should implement equality correctly', () {
      final passage1 = Passage.fromText(
        id: testId,
        text: testText,
        reference: testReference,
      );

      final passage2 = Passage.fromText(
        id: testId,
        text: testText,
        reference: testReference,
      );

      expect(passage1, passage2);
      expect(passage1.hashCode, passage2.hashCode);
    });

    test('should tokenize text correctly with extra whitespace', () {
      final passage = Passage.fromText(
        id: testId,
        text: 'Love  your    enemies',
        reference: testReference,
      );

      expect(passage.words, ['Love', 'your', 'enemies']);
    });

    test('should have readable toString', () {
      final passage = Passage.fromText(
        id: testId,
        text: testText,
        reference: testReference,
      );

      final string = passage.toString();

      expect(string, contains(testId));
      expect(string, contains(testReference));
      expect(string, contains('10'));
    });
  });
}
