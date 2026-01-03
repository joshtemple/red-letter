import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/clause_segmentation.dart';
import 'package:red_letter/models/passage.dart';

void main() {
  group('ClauseSegmentation', () {
    test('segments simple passage with commas', () {
      final passage = Passage.fromText(
        id: 'test-1',
        text: 'Love your enemies, bless those who curse you.',
        reference: 'Test 1:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      expect(segmentation.clauseCount, 2);
      expect(segmentation.clauses[0].text, 'Love your enemies,');
      expect(segmentation.clauses[1].text, 'bless those who curse you.');
    });

    test('segments passage with multiple punctuation types', () {
      final passage = Passage.fromText(
        id: 'test-2',
        text: 'First clause. Second clause, with comma; and third clause!',
        reference: 'Test 2:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      expect(segmentation.clauseCount, 4);
      expect(segmentation.clauses[0].text, 'First clause.');
      expect(segmentation.clauses[1].text, 'Second clause,');
      expect(segmentation.clauses[2].text, 'with comma;');
      expect(segmentation.clauses[3].text, 'and third clause!');
    });

    test('handles passage with no punctuation', () {
      final passage = Passage.fromText(
        id: 'test-3',
        text: 'This has no punctuation',
        reference: 'Test 3:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      expect(segmentation.clauseCount, 1);
      expect(segmentation.clauses[0].text, 'This has no punctuation');
    });

    test('handles empty passage', () {
      final passage = Passage.fromText(
        id: 'test-4',
        text: '',
        reference: 'Test 4:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      expect(segmentation.clauseCount, 0);
    });

    test('getClauseForWordIndex returns correct clause', () {
      final passage = Passage.fromText(
        id: 'test-5',
        text: 'First part, second part.',
        reference: 'Test 5:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      // "First" is at index 0
      final clause1 = segmentation.getClauseForWordIndex(0);
      expect(clause1, isNotNull);
      expect(clause1!.text, 'First part,');

      // "second" is at index 2 (after "First", "part,")
      final clause2 = segmentation.getClauseForWordIndex(2);
      expect(clause2, isNotNull);
      expect(clause2!.text, 'second part.');
    });

    test('getClauseAt returns correct clause by index', () {
      final passage = Passage.fromText(
        id: 'test-6',
        text: 'One, two, three.',
        reference: 'Test 6:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      expect(segmentation.getClauseAt(0)?.text, 'One,');
      expect(segmentation.getClauseAt(1)?.text, 'two,');
      expect(segmentation.getClauseAt(2)?.text, 'three.');
      expect(segmentation.getClauseAt(3), isNull);
      expect(segmentation.getClauseAt(-1), isNull);
    });

    test('Clause.containsWordIndex works correctly', () {
      final passage = Passage.fromText(
        id: 'test-7',
        text: 'First, second.',
        reference: 'Test 7:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);
      final firstClause = segmentation.clauses[0];

      expect(firstClause.containsWordIndex(0), true); // "First,"
      expect(firstClause.containsWordIndex(1), false); // "second."
    });

    test('Clause.wordIndices returns all indices', () {
      final passage = Passage.fromText(
        id: 'test-8',
        text: 'One two three, four five.',
        reference: 'Test 8:1',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      // First clause: "One two three,"
      final firstClause = segmentation.clauses[0];
      expect(firstClause.wordIndices, [0, 1, 2]);

      // Second clause: "four five."
      final secondClause = segmentation.clauses[1];
      expect(secondClause.wordIndices, [3, 4]);
    });

    test('real scripture example: Matthew 5:44', () {
      final passage = Passage.fromText(
        id: 'mat-5-44',
        text:
            'But I say to you, Love your enemies and pray for those who persecute you.',
        reference: 'Matthew 5:44',
      );

      final segmentation = ClauseSegmentation.fromPassage(passage);

      expect(segmentation.clauseCount, 2);
      expect(segmentation.clauses[0].text, 'But I say to you,');
      expect(segmentation.clauses[1].text, 'Love your enemies and pray for those who persecute you.');
    });
  });
}
