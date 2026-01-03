import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/passage_dao.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/services/working_set_service.dart';

void main() {
  late AppDatabase database;
  late PassageDAO passageDAO;
  late UserProgressDAO progressDAO;
  late WorkingSetService workingSetService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    passageDAO = PassageDAO(database);
    progressDAO = UserProgressDAO(database);
    workingSetService = WorkingSetService(progressDAO);
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper to insert a test passage
  Future<void> insertTestPassage(String passageId) async {
    await passageDAO.insertPassage(
      PassagesCompanion.insert(
        passageId: passageId,
        translationId: 'niv',
        reference: 'Test $passageId',
        passageText: 'Test passage text',
        book: 'TestBook',
        chapter: 1,
        startVerse: 1,
        endVerse: 1,
      ),
    );
  }

  group('WorkingSetService - New Card Management', () {
    test('getAvailableNewCards returns limited new cards by default', () async {
      // Create 10 new passages with progress
      for (int i = 1; i <= 10; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      // Should return only 5 (default limit)
      final newCards = await workingSetService.getAvailableNewCards();
      expect(newCards, hasLength(5));

      // All should be in learning state with no reviews
      for (final card in newCards) {
        expect(card.state, equals(0)); // Learning
        expect(card.lastReviewed, isNull);
      }
    });

    test('getAvailableNewCards respects override limit', () async {
      // Create 10 new passages
      for (int i = 1; i <= 10; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      // Override to get only 3
      final newCards =
          await workingSetService.getAvailableNewCards(overrideLimit: 3);
      expect(newCards, hasLength(3));
    });

    test('getAvailableNewCards returns all when fewer than limit', () async {
      // Create only 3 new passages
      for (int i = 1; i <= 3; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      // Should return all 3 even though default limit is 5
      final newCards = await workingSetService.getAvailableNewCards();
      expect(newCards, hasLength(3));
    });

    test('getAvailableNewCards excludes cards that have been reviewed',
        () async {
      // Create 5 new passages
      for (int i = 1; i <= 5; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      // Review one of them
      await progressDAO.updateFSRSData(
        passageId: 'test-1',
        stability: 1.0,
        difficulty: 5.0,
        step: 1,
        state: 0, // Still learning but has been reviewed
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now().add(const Duration(minutes: 10)),
      );

      // Should return only 4 (excluding the reviewed one)
      final newCards = await workingSetService.getAvailableNewCards();
      expect(newCards, hasLength(4));
      expect(newCards.every((c) => c.passageId != 'test-1'), isTrue);
    });

    test('getTotalNewCardsCount returns correct count', () async {
      // Create 7 new passages
      for (int i = 1; i <= 7; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      final count = await workingSetService.getTotalNewCardsCount();
      expect(count, equals(7));
    });

    test('canIntroduceMoreNewCards returns true when new cards exist',
        () async {
      await insertTestPassage('test-1');
      await progressDAO.createProgress('test-1');

      final canIntroduce = await workingSetService.canIntroduceMoreNewCards();
      expect(canIntroduce, isTrue);
    });

    test('canIntroduceMoreNewCards returns false when no new cards', () async {
      // No new cards created
      final canIntroduce = await workingSetService.canIntroduceMoreNewCards();
      expect(canIntroduce, isFalse);
    });

    test('getRemainingNewCardBudget returns configured limit', () async {
      // This is a simple implementation for now
      final remaining = await workingSetService.getRemainingNewCardBudget();
      expect(remaining, equals(WorkingSetService.defaultNewCardsPerDay));
    });
  });

  group('WorkingSetService - Custom Configuration', () {
    test('custom newCardsPerDay limit is respected', () async {
      final customService = WorkingSetService(
        progressDAO,
        newCardsPerDay: 3,
      );

      // Create 10 new passages
      for (int i = 1; i <= 10; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      final newCards = await customService.getAvailableNewCards();
      expect(newCards, hasLength(3));
    });

    test('zero limit returns no cards', () async {
      final zeroService = WorkingSetService(
        progressDAO,
        newCardsPerDay: 0,
      );

      // Create new passages
      for (int i = 1; i <= 5; i++) {
        await insertTestPassage('test-$i');
        await progressDAO.createProgress('test-$i');
      }

      final newCards = await zeroService.getAvailableNewCards();
      expect(newCards, isEmpty);
    });
  });
}
