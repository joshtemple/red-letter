import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:red_letter/controllers/session_controller.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';
import 'package:red_letter/services/working_set_service.dart';
import 'package:drift/drift.dart';
import 'package:red_letter/models/practice_step.dart';

@GenerateMocks([UserProgressDAO, WorkingSetService, FSRSSchedulerService])
import 'review_session_controller_test.mocks.dart';

void main() {
  late SessionController controller;
  late MockUserProgressDAO mockProgressDAO;
  late MockWorkingSetService mockWorkingSetService;
  late MockFSRSSchedulerService mockFSRSService;

  setUp(() {
    mockProgressDAO = MockUserProgressDAO();
    mockWorkingSetService = MockWorkingSetService();
    mockFSRSService = MockFSRSSchedulerService();

    controller = SessionController(
      progressDAO: mockProgressDAO,
      workingSetService: mockWorkingSetService,
      fsrsService: mockFSRSService,
    );
  });

  group('SessionController', () {
    final testProgress = UserProgress(
      id: 1, // Required
      passageId: '1',
      masteryLevel: 1,
      stability: 1.0,
      difficulty: 1.0,
      step: 0,
      state: 1, // Review
      lastReviewed: DateTime.now(),
      nextReview: DateTime.now(),
    );

    test('loadSession populates cards', () async {
      when(
        mockProgressDAO.getReviewQueue(limit: anyNamed('limit')),
      ).thenAnswer((_) async => [testProgress]);
      when(
        mockWorkingSetService.getAvailableNewCards(
          overrideLimit: anyNamed('overrideLimit'),
        ),
      ).thenAnswer((_) async => []);

      await controller.loadSession();

      expect(controller.cards.length, 1);
      expect(controller.currentIndex, 0);
      expect(controller.isLoaded, true);
    });

    test('submitReview advances to next card', () async {
      // Setup
      when(
        mockProgressDAO.getReviewQueue(limit: anyNamed('limit')),
      ).thenAnswer((_) async => [testProgress]);
      when(
        mockWorkingSetService.getAvailableNewCards(
          overrideLimit: anyNamed('overrideLimit'),
        ),
      ).thenAnswer((_) async => []);

      await controller.loadSession();

      // Mock submit behavior
      final metrics = SessionMetrics(
        passageText: 'test',
        userInput: 'test',
        durationMs: 1000,
        levenshteinDistance: 0,
      );

      when(
        mockFSRSService.reviewPassage(
          passageId: anyNamed('passageId'),
          progress: anyNamed('progress'),
          rating: anyNamed('rating'),
        ),
      ).thenReturn(UserProgressTableCompanion.insert(passageId: '1'));

      when(mockProgressDAO.upsertProgress(any)).thenAnswer((_) async {});

      // Act
      await controller.submitReview(metrics);

      // Assert
      expect(controller.currentIndex, 1);
      expect(controller.completedReviews.length, 1);
    });

    test('handleStepCompletion persists reflection', () async {
      when(
        mockProgressDAO.getReviewQueue(limit: anyNamed('limit')),
      ).thenAnswer((_) async => [testProgress]);
      when(
        mockWorkingSetService.getAvailableNewCards(
          overrideLimit: anyNamed('overrideLimit'),
        ),
      ).thenAnswer((_) async => []);
      await controller.loadSession();

      when(
        mockProgressDAO.updateSemanticReflection(any, any),
      ).thenAnswer((_) async => 1);

      await controller.handleStepCompletion(
        passageId: '1',
        step: PracticeStep.reflection,
        metrics: SessionMetrics(
          passageText: '',
          userInput: 'My reflection',
          durationMs: 0,
          levenshteinDistance: 0,
        ),
      );

      // Verify NO DB calls were made
      verifyNever(mockProgressDAO.updateSemanticReflection(any, any));
      verifyNever(mockProgressDAO.updateMasteryLevel(any, any));

      // Verify in-memory update happened
      expect(controller.cards[0].semanticReflection, 'My reflection');
      expect(controller.cards[0].masteryLevel, 1);
    });
  });
}
