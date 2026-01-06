import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:red_letter/controllers/session_controller.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

// @GenerateMocks([UserProgressDAO, WorkingSetService, FSRSSchedulerService])
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

  group('SessionController Flow Logic', () {
    final reviewCard = UserProgress(
      id: 1,
      passageId: '1',
      masteryLevel: 5,
      step: 0,
      state: 1, // Review state
      lastReviewed: DateTime.now(),
      nextReview: DateTime.now(),
      stability: 1.0,
      difficulty: 5.0,
    );

    final learningCard = UserProgress(
      id: 2,
      passageId: '2',
      masteryLevel: 4,
      step: 3,
      state: 0, // New/Learning state
      lastReviewed: null,
      nextReview: null,
      stability: 0.0,
      difficulty: 0.0,
    );

    setUp(() async {
      // Setup successful load for all tests
      when(
        mockProgressDAO.getReviewQueue(limit: anyNamed('limit')),
      ).thenAnswer((_) async => [reviewCard]);
      when(
        mockWorkingSetService.getAvailableNewCards(
          overrideLimit: anyNamed('overrideLimit'),
        ),
      ).thenAnswer((_) async => [learningCard]);

      // Handle the initial DB creation for new cards if needed
      if (learningCard.id == -1) {
        when(mockProgressDAO.createProgress(any)).thenAnswer((_) async => 2);
      }

      await controller.loadSession();
    });

    test(
      'handlePassageCompletion in Review Flow (Success) submits calculated rating and advances',
      () async {
        // Current card is reviewCard (index 0)
        expect(controller.currentCard?.id, 1);
        expect(controller.currentCard?.state, 1);

        final metrics = SessionMetrics(
          passageText: 'text',
          userInput: 'text',
          durationMs: 1000,
          levenshteinDistance: 0, // Perfect match -> Good/Easy
        );

        // Expect FSRS review with calculated rating (likely Easy or Good)
        when(
          mockFSRSService.reviewPassage(
            passageId: '1',
            progress: reviewCard,
            rating: argThat(
              isIn([fsrs.Rating.good, fsrs.Rating.easy, fsrs.Rating.hard]),
              named: 'rating',
            ),
          ),
        ).thenReturn(UserProgressTableCompanion.insert(passageId: '1'));

        when(mockProgressDAO.upsertProgress(any)).thenAnswer((_) async {});

        await controller.handlePassageCompletion(metrics);

        // Verify advance
        expect(controller.currentIndex, 1);
      },
    );

    test(
      'handlePassageCompletion in Review Flow (Failure) submits Again rating and advances',
      () async {
        // Current card is reviewCard (index 0)

        final metrics = SessionMetrics(
          passageText: 'text',
          userInput: 'wrong', // Bad input
          durationMs: 1000,
          levenshteinDistance: 10,
        );

        // Expect FSRS review with Again rating
        when(
          mockFSRSService.reviewPassage(
            passageId: '1',
            progress: reviewCard,
            rating: fsrs.Rating.again,
          ),
        ).thenReturn(UserProgressTableCompanion.insert(passageId: '1'));

        when(mockProgressDAO.upsertProgress(any)).thenAnswer((_) async {});

        await controller.handlePassageCompletion(metrics);

        // Verify advance (Key requirement: Review failures advance/reschedule, do not regress in session)
        expect(controller.currentIndex, 1);
      },
    );

    test(
      'handlePassageCompletion in Learning Flow (Success) submits Good rating and advances',
      () async {
        // Skip first card to get to learning card
        controller.skipCard();
        expect(controller.currentCard?.id, 2);
        expect(controller.currentCard?.state, 0);

        final metrics = SessionMetrics(
          passageText: 'text',
          userInput: 'text',
          durationMs: 1000,
          levenshteinDistance: 0,
        );

        // Expect FSRS review with FORCED Good rating (Graduation)
        when(
          mockFSRSService.reviewPassage(
            passageId: '2',
            progress: learningCard,
            rating: fsrs.Rating.good, // Forced good
          ),
        ).thenReturn(UserProgressTableCompanion.insert(passageId: '2'));

        when(mockProgressDAO.upsertProgress(any)).thenAnswer((_) async {});

        await controller.handlePassageCompletion(metrics);

        // Verify advance
        expect(controller.currentIndex, 2); // 0 -> 1 -> 2 (end)
      },
    );
  });
}
