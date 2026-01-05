import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';

void main() {
  late AppDatabase database;
  late UserProgressDAO dao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = UserProgressDAO(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('UserProgressDAO - getPotentialNewCards', () {
    test('returns unstarted passages as UserProgress', () async {
      // 1. Seed a passage that has NO progress
      await database
          .into(database.passages)
          .insert(
            PassagesCompanion(
              passageId: const Value('unstarted-1'),
              reference: const Value('Ref 1'),
              passageText: const Value('Text 1'),
              translationId: const Value('esv'),
              book: const Value('Book'),
              chapter: const Value(1),
              startVerse: const Value(1),
              endVerse: const Value(1),
            ),
          );

      // Verify
      final newCards = await dao.getPotentialNewCards();
      expect(newCards.length, 1);
      expect(newCards.first.passageId, 'unstarted-1');
      expect(newCards.first.id, -1); // Check synthetic ID
      expect(newCards.first.difficulty, 5.0); // Check default difficulty
    });

    test('returns passages with learning progress but never reviewed', () async {
      // 1. Seed a passage
      await database
          .into(database.passages)
          .insert(
            PassagesCompanion(
              passageId: const Value('learning-1'),
              reference: const Value('Ref 1'),
              passageText: const Value('Text 1'),
              translationId: const Value('esv'),
              book: const Value('Book'),
              chapter: const Value(1),
              startVerse: const Value(1),
              endVerse: const Value(1),
            ),
          );

      // 2. Add progress: state=0 (learning), lastReviewed=null (never reviewed)
      await dao.createProgress('learning-1');

      // Verify
      final newCards = await dao.getPotentialNewCards();
      expect(newCards.length, 1);
      expect(newCards.first.passageId, 'learning-1');
      expect(newCards.first.id, isNot(-1)); // Should be real ID
    });

    test('does NOT return passages that have been reviewed', () async {
      // 1. Seed a passage
      await database
          .into(database.passages)
          .insert(
            PassagesCompanion(
              passageId: const Value('reviewed-1'),
              reference: const Value('Ref 1'),
              passageText: const Value('Text 1'),
              translationId: const Value('esv'),
              book: const Value('Book'),
              chapter: const Value(1),
              startVerse: const Value(1),
              endVerse: const Value(1),
            ),
          );

      // 2. Add progress with lastReviewed set
      await dao.createProgress('reviewed-1');
      await dao.updateFSRSData(
        passageId: 'reviewed-1',
        stability: 1.0,
        difficulty: 5.0,
        step: 0,
        state: 0,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now().add(const Duration(days: 1)),
      );

      // Verify
      final newCards = await dao.getPotentialNewCards();
      expect(newCards, isEmpty);
    });

    test('limit parameter works correctly', () async {
      // Insert 5 unstarted passages
      for (int i = 0; i < 5; i++) {
        await database
            .into(database.passages)
            .insert(
              PassagesCompanion(
                passageId: Value('p-$i'),
                reference: const Value('Ref'),
                passageText: const Value('Text'),
                translationId: const Value('esv'),
                book: const Value('Book'),
                chapter: const Value(1),
                startVerse: Value(i),
                endVerse: Value(i),
              ),
            );
      }

      final cards = await dao.getPotentialNewCards(limit: 3);
      expect(cards.length, 3);
    });
  });
}
