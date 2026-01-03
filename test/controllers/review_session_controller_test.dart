import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/controllers/review_session_controller.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/passage_dao.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';
import 'package:red_letter/services/working_set_service.dart';

void main() {
  late AppDatabase database;
  late PassageDAO passageDAO;
  late UserProgressDAO progressDAO;
  late WorkingSetService workingSetService;
  late FSRSSchedulerService fsrsService;
  late ReviewSessionController controller;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    passageDAO = PassageDAO(database);
    progressDAO = UserProgressDAO(database);
    workingSetService = WorkingSetService(progressDAO);
    fsrsService = FSRSSchedulerService();

    controller = ReviewSessionController(
      progressDAO: progressDAO,
      workingSetService: workingSetService,
      fsrsService: fsrsService,
    );
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  /// Helper to insert a test passage
  Future<void> insertTestPassage(String passageId, String text) async {
    await passageDAO.insertPassage(
      PassagesCompanion.insert(
        passageId: passageId,
        translationId: 'niv',
        reference: 'Test $passageId',
        passageText: text,
        book: 'TestBook',
        chapter: 1,
        startVerse: 1,
        endVerse: 1,
      ),
    );
  }

  group('ReviewSessionController - Session Loading', () {
    test('initial state is empty and not loaded', () {
      expect(controller.isLoaded, isFalse);
      expect(controller.cards, isEmpty);
      expect(controller.currentIndex, equals(0));
      expect(controller.isComplete, isFalse);
    });

    test('loadSession loads due review cards', () async {
      // Create passages with due reviews
      for (int i = 1; i <= 3; i++) {
        await insertTestPassage('test-$i', 'Test text $i');
        await progressDAO.createProgress('test-$i');

        // Mark as due for review
        await progressDAO.updateFSRSData(
          passageId: 'test-$i',
          stability: 1.0,
          difficulty: 5.0,
          step: null,
          state: 1, // Review state
          lastReviewed: DateTime.now().subtract(const Duration(days: 2)),
          nextReview: DateTime.now().subtract(const Duration(days: 1)),
        );
      }

      await controller.loadSession();

      expect(controller.isLoaded, isTrue);
      expect(controller.cards, hasLength(3));
      expect(controller.currentIndex, equals(0));
      expect(controller.currentCard, isNotNull);
    });

    test('loadSession includes new cards within working set budget', () async {
      // Create 3 due reviews
      for (int i = 1; i <= 3; i++) {
        await insertTestPassage('review-$i', 'Review text $i');
        await progressDAO.createProgress('review-$i');
        await progressDAO.updateFSRSData(
          passageId: 'review-$i',
          stability: 1.0,
          difficulty: 5.0,
          step: null,
          state: 1,
          lastReviewed: DateTime.now().subtract(const Duration(days: 1)),
          nextReview: DateTime.now().subtract(const Duration(hours: 1)),
        );
      }

      // Create 5 new cards (default budget is 5)
      for (int i = 1; i <= 5; i++) {
        await insertTestPassage('new-$i', 'New text $i');
        await progressDAO.createProgress('new-$i');
      }

      await controller.loadSession();

      expect(controller.isLoaded, isTrue);
      expect(controller.cards, hasLength(8)); // 3 reviews + 5 new
    });

    test('loadSession respects review and new card limits', () async {
      // Create 10 due reviews
      for (int i = 1; i <= 10; i++) {
        await insertTestPassage('review-$i', 'Review text $i');
        await progressDAO.createProgress('review-$i');
        await progressDAO.updateFSRSData(
          passageId: 'review-$i',
          stability: 1.0,
          difficulty: 5.0,
          step: null,
          state: 1,
          lastReviewed: DateTime.now().subtract(const Duration(days: 1)),
          nextReview: DateTime.now().subtract(const Duration(hours: 1)),
        );
      }

      // Create 10 new cards
      for (int i = 1; i <= 10; i++) {
        await insertTestPassage('new-$i', 'New text $i');
        await progressDAO.createProgress('new-$i');
      }

      await controller.loadSession(reviewLimit: 5, newCardLimit: 2);

      expect(controller.cards, hasLength(7)); // 5 reviews + 2 new
    });
  });

  group('ReviewSessionController - Session Navigation', () {
    setUp(() async {
      // Create 3 cards for navigation tests
      for (int i = 1; i <= 3; i++) {
        await insertTestPassage('test-$i', 'Test text $i');
        await progressDAO.createProgress('test-$i');
      }

      await controller.loadSession();
    });

    test('currentCard returns first card initially', () {
      expect(controller.currentCard, isNotNull);
      expect(controller.currentCard!.passageId, equals('test-1'));
      expect(controller.currentIndex, equals(0));
    });

    test('skipCard advances to next card', () {
      controller.skipCard();

      expect(controller.currentIndex, equals(1));
      expect(controller.currentCard!.passageId, equals('test-2'));
      expect(controller.completedReviews, isEmpty); // No review submitted
    });

    test('previousCard goes back to previous card', () {
      controller.skipCard(); // Move to index 1
      controller.skipCard(); // Move to index 2
      controller.previousCard(); // Back to index 1

      expect(controller.currentIndex, equals(1));
      expect(controller.currentCard!.passageId, equals('test-2'));
    });

    test('previousCard does nothing at start', () {
      controller.previousCard(); // Try to go before index 0

      expect(controller.currentIndex, equals(0));
    });
  });

  group('ReviewSessionController - Review Submission', () {
    setUp(() async {
      // Create 2 cards
      for (int i = 1; i <= 2; i++) {
        await insertTestPassage('test-$i', 'Test text $i');
        await progressDAO.createProgress('test-$i');
      }

      await controller.loadSession();
    });

    test('submitReview updates card and advances', () async {
      final metrics = SessionMetrics(
        passageText: 'Test text 1',
        userInput: 'Test text 1',
        durationMs: 5000,
        levenshteinDistance: 0,
      );

      await controller.submitReview(metrics);

      expect(controller.currentIndex, equals(1));
      expect(controller.completedReviews, hasLength(1));
      expect(controller.completedReviews.first.accuracy, equals(1.0));

      // Verify database was updated
      final progress = await progressDAO.getProgressByPassageId('test-1');
      expect(progress, isNotNull);
      expect(progress!.lastReviewed, isNotNull);
      expect(progress.nextReview, isNotNull);
    });

    test('isComplete is true after all cards reviewed', () async {
      final metrics1 = SessionMetrics(
        passageText: 'Test text 1',
        userInput: 'Test text 1',
        durationMs: 5000,
        levenshteinDistance: 0,
      );

      final metrics2 = SessionMetrics(
        passageText: 'Test text 2',
        userInput: 'Test text 2',
        durationMs: 5000,
        levenshteinDistance: 0,
      );

      await controller.submitReview(metrics1);
      expect(controller.isComplete, isFalse);

      await controller.submitReview(metrics2);
      expect(controller.isComplete, isTrue);
      expect(controller.currentCard, isNull);
    });
  });

  group('ReviewSessionController - Session Statistics', () {
    setUp(() async {
      // Create 3 cards
      for (int i = 1; i <= 3; i++) {
        await insertTestPassage('test-$i', 'Test text $i');
        await progressDAO.createProgress('test-$i');
      }

      await controller.loadSession();
    });

    test('getSessionStats returns zeros initially', () {
      final stats = controller.getSessionStats();

      expect(stats['cardsReviewed'], equals(0));
      expect(stats['averageAccuracy'], equals(0.0));
    });

    test('getSessionStats calculates averages correctly', () async {
      // Submit 2 reviews with different metrics
      await controller.submitReview(SessionMetrics(
        passageText: 'Test text 1',
        userInput: 'Test text 1',
        durationMs: 5000,
        levenshteinDistance: 0,
      ));

      await controller.submitReview(SessionMetrics(
        passageText: 'Test text 2 long',
        userInput: 'Test text 2',
        durationMs: 10000,
        levenshteinDistance: 5,
      ));

      final stats = controller.getSessionStats();
      expect(stats['cardsReviewed'], equals(2));
      expect(stats['averageAccuracy'], greaterThan(0.0));
      expect(stats['averageWPM'], greaterThan(0.0));
    });

    test('progressPercent calculates correctly', () {
      expect(controller.progressPercent, equals(0.0));

      controller.skipCard();
      expect(controller.progressPercent, closeTo(33.3, 0.1));

      controller.skipCard();
      expect(controller.progressPercent, closeTo(66.7, 0.1));

      controller.skipCard();
      expect(controller.progressPercent, equals(100.0));
    });

    test('remainingCount decreases as cards are reviewed', () async {
      expect(controller.remainingCount, equals(3));

      await controller.submitReview(SessionMetrics(
        passageText: 'Test text 1',
        userInput: 'Test text 1',
        durationMs: 5000,
        levenshteinDistance: 0,
      ));

      expect(controller.remainingCount, equals(2));
    });
  });

  group('ReviewSessionController - Session Reset', () {
    test('resetSession returns to initial state', () async {
      // Load a session
      for (int i = 1; i <= 3; i++) {
        await insertTestPassage('test-$i', 'Test text $i');
        await progressDAO.createProgress('test-$i');
      }

      await controller.loadSession();

      // Advance and review
      await controller.submitReview(SessionMetrics(
        passageText: 'Test text 1',
        userInput: 'Test text 1',
        durationMs: 5000,
        levenshteinDistance: 0,
      ));

      expect(controller.isLoaded, isTrue);
      expect(controller.currentIndex, equals(1));

      // Reset
      controller.resetSession();

      expect(controller.isLoaded, isFalse);
      expect(controller.cards, isEmpty);
      expect(controller.currentIndex, equals(0));
      expect(controller.completedReviews, isEmpty);
    });
  });
}
