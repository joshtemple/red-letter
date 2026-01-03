import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';

void main() {
  late FSRSSchedulerService service;

  setUp(() {
    service = FSRSSchedulerService();
  });

  /// Helper to create UserProgress with FSRS fields
  UserProgress createProgress({
    required int id,
    required String passageId,
    int masteryLevel = 1,
    int state = 0,
    int? step = 0,
    double stability = 1.0,
    double difficulty = 5.0,
    required DateTime? lastReviewed,
    required DateTime? nextReview,
    String? semanticReflection,
  }) {
    return UserProgress(
      id: id,
      passageId: passageId,
      masteryLevel: masteryLevel,
      state: state,
      step: step,
      stability: stability,
      difficulty: difficulty,
      lastReviewed: lastReviewed,
      nextReview: nextReview,
      semanticReflection: semanticReflection,
      lastSync: null,
    );
  }

  group('FSRSSchedulerService - Initialization', () {
    test('creates service with default scheduler', () {
      expect(service.scheduler, isNotNull);
      expect(service.scheduler.desiredRetention, equals(0.9));
      expect(service.scheduler.maximumInterval, equals(365));
      expect(service.scheduler.enableFuzzing, isTrue);
    });

    test('accepts custom scheduler in constructor', () {
      final customScheduler = fsrs.Scheduler(
        desiredRetention: 0.85,
        maximumInterval: 180,
        enableFuzzing: false,
      );

      final customService = FSRSSchedulerService(scheduler: customScheduler);

      expect(customService.scheduler.desiredRetention, equals(0.85));
      expect(customService.scheduler.maximumInterval, equals(180));
      expect(customService.scheduler.enableFuzzing, isFalse);
    });

    test('default scheduler has learning steps configured', () {
      expect(
        service.scheduler.learningSteps,
        equals([
          const Duration(minutes: 1),
          const Duration(minutes: 10),
        ]),
      );
    });

    test('default scheduler has relearning steps configured', () {
      expect(
        service.scheduler.relearningSteps,
        equals([const Duration(minutes: 10)]),
      );
    });
  });

  group('FSRSSchedulerService - Review Passage', () {
    test('reviews passage with "good" rating and updates schedule', () {
      final progress = createProgress(
        id: 1,
        passageId: 'mat-5-44',
        state: 0, // Learning
        stability: 1.0,
        difficulty: 5.0,
        lastReviewed: DateTime(2024, 1, 1),
        nextReview: DateTime(2024, 1, 1),
      );

      final companion = service.reviewPassage(
        passageId: 'mat-5-44',
        progress: progress,
        rating: fsrs.Rating.good,
      );

      expect(companion.passageId.present, isTrue);
      expect(companion.passageId.value, equals('mat-5-44'));
      expect(companion.nextReview.present, isTrue);
      expect(companion.lastReviewed.present, isTrue);
      expect(companion.nextReview.value, isNotNull);
      expect(
        companion.nextReview.value!.isAfter(DateTime(2024, 1, 1)),
        isTrue,
      );
    });

    test('reviews passage with "again" rating for relearning', () {
      final progress = createProgress(
        id: 2,
        passageId: 'jhn-3-16',
        masteryLevel: 3,
        state: 1, // Review
        step: null,
        stability: 14.0,
        difficulty: 4.0,
        lastReviewed: DateTime(2024, 1, 10),
        nextReview: DateTime(2024, 1, 24),
      );

      final companion = service.reviewPassage(
        passageId: 'jhn-3-16',
        progress: progress,
        rating: fsrs.Rating.again,
      );

      // "Again" rating should transition to relearning
      expect(companion.nextReview.present, isTrue);
      expect(companion.stability.present, isTrue);
      // Stability should decrease on failure
      expect(companion.stability.value, lessThan(progress.stability));
    });

    test('reviews passage with "easy" rating extends stability', () {
      final progress = createProgress(
        id: 3,
        passageId: 'rom-8-28',
        masteryLevel: 2,
        state: 1, // Review
        step: null,
        stability: 7.0,
        difficulty: 5.0,
        lastReviewed: DateTime(2024, 1, 5),
        nextReview: DateTime(2024, 1, 12),
      );

      final companionGood = service.reviewPassage(
        passageId: 'rom-8-28',
        progress: progress,
        rating: fsrs.Rating.good,
      );

      final companionEasy = service.reviewPassage(
        passageId: 'rom-8-28',
        progress: progress,
        rating: fsrs.Rating.easy,
      );

      // "Easy" should result in higher stability than "Good"
      expect(
        companionEasy.stability.value,
        greaterThan(companionGood.stability.value),
      );
    });

    test('allows custom mastery level override', () {
      final progress = createProgress(
        id: 4,
        passageId: 'test-1',
        masteryLevel: 2,
        state: 1, // Review
        stability: 15.0,
        difficulty: 4.0,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now(),
      );

      final companion = service.reviewPassage(
        passageId: 'test-1',
        progress: progress,
        rating: fsrs.Rating.easy,
        customMasteryLevel: 4, // Override to "locked-in"
      );

      expect(companion.masteryLevel.value, equals(4));
    });
  });

  group('FSRSSchedulerService - Calculate Next Review', () {
    test('calculates future review date without updating data', () {
      final progress = createProgress(
        id: 5,
        passageId: 'test-2',
        masteryLevel: 1,
        state: 0, // Learning
        stability: 1.0,
        difficulty: 5.0,
        lastReviewed: DateTime(2024, 1, 1),
        nextReview: DateTime(2024, 1, 2),
      );

      final nextReview = service.calculateNextReview(
        progress: progress,
        passageId: 'test-2',
        rating: fsrs.Rating.good,
      );

      expect(nextReview, isA<DateTime>());
      expect(nextReview.isAfter(DateTime(2024, 1, 1)), isTrue);
    });

    test('different ratings produce different next review dates', () {
      final progress = createProgress(
        id: 6,
        passageId: 'test-3',
        masteryLevel: 2,
        state: 1, // Review
        stability: 10.0,
        difficulty: 5.0,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now(),
      );

      final againDate = service.calculateNextReview(
        progress: progress,
        passageId: 'test-3',
        rating: fsrs.Rating.again,
      );

      final hardDate = service.calculateNextReview(
        progress: progress,
        passageId: 'test-3',
        rating: fsrs.Rating.hard,
      );

      final goodDate = service.calculateNextReview(
        progress: progress,
        passageId: 'test-3',
        rating: fsrs.Rating.good,
      );

      final easyDate = service.calculateNextReview(
        progress: progress,
        passageId: 'test-3',
        rating: fsrs.Rating.easy,
      );

      // Verify ordering: again < hard <= good < easy
      expect(againDate.isBefore(hardDate), isTrue);
      expect(hardDate.isBefore(easyDate) || hardDate.isAtSameMomentAs(goodDate), isTrue);
      expect(goodDate.isBefore(easyDate), isTrue);
    });
  });

  group('FSRSSchedulerService - Retrievability', () {
    test('returns null retrievability for never-reviewed passage', () {
      final progress = createProgress(
        id: 7,
        passageId: 'test-4',
        masteryLevel: 0,
        state: 0,
        stability: 1.0, // Use non-zero stability (FSRS returns NaN for 0)
        difficulty: 5.0,
        lastReviewed: null, // This triggers null return
        nextReview: null,
      );

      final retrievability = service.getRetrievability(
        progress: progress,
        passageId: 'test-4',
      );

      expect(retrievability, isNull);
    });

    test('returns retrievability for reviewed passage', () {
      final progress = createProgress(
        id: 8,
        passageId: 'test-5',
        masteryLevel: 2,
        state: 1, // Review
        stability: 14.0,
        difficulty: 5.0,
        lastReviewed: DateTime.now().subtract(const Duration(days: 3)),
        nextReview: DateTime.now().add(const Duration(days: 11)),
      );

      final retrievability = service.getRetrievability(
        progress: progress,
        passageId: 'test-5',
      );

      expect(retrievability, isNotNull);
      expect(retrievability, greaterThanOrEqualTo(0.0));
      expect(retrievability, lessThanOrEqualTo(1.0));
    });

    test('retrievability decreases over time', () {
      final baseTime = DateTime.now();

      final progress1Day = createProgress(
        id: 9,
        passageId: 'test-6',
        masteryLevel: 2,
        state: 1, // Review
        stability: 20.0,
        difficulty: 5.0,
        lastReviewed: baseTime.subtract(const Duration(days: 1)),
        nextReview: baseTime.add(const Duration(days: 19)),
      );

      final progress7Days = createProgress(
        id: 10,
        passageId: 'test-7',
        masteryLevel: 2,
        state: 1, // Review
        stability: 20.0,
        difficulty: 5.0,
        lastReviewed: baseTime.subtract(const Duration(days: 7)),
        nextReview: baseTime.add(const Duration(days: 13)),
      );

      final retrievability1Day = service.getRetrievability(
        progress: progress1Day,
        passageId: 'test-6',
      );

      final retrievability7Days = service.getRetrievability(
        progress: progress7Days,
        passageId: 'test-7',
      );

      // More time elapsed = lower retrievability
      expect(retrievability1Day, greaterThan(retrievability7Days!));
    });
  });

  group('FSRSSchedulerService - Preview Next Reviews', () {
    test('returns preview dates for all rating options', () {
      final progress = createProgress(
        id: 11,
        passageId: 'test-8',
        masteryLevel: 2,
        state: 1, // Review
        stability: 10.0,
        difficulty: 5.0,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now(),
      );

      final preview = service.previewNextReviewDates(
        progress: progress,
        passageId: 'test-8',
      );

      expect(preview, hasLength(4)); // 4 rating options
      expect(preview.keys, containsAll(fsrs.Rating.values));
      expect(preview[fsrs.Rating.again], isA<DateTime>());
      expect(preview[fsrs.Rating.hard], isA<DateTime>());
      expect(preview[fsrs.Rating.good], isA<DateTime>());
      expect(preview[fsrs.Rating.easy], isA<DateTime>());
    });

    test('preview dates are ordered correctly', () {
      final progress = createProgress(
        id: 12,
        passageId: 'test-9',
        masteryLevel: 2,
        state: 1, // Review
        stability: 20.0,
        difficulty: 5.0,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now(),
      );

      final preview = service.previewNextReviewDates(
        progress: progress,
        passageId: 'test-9',
      );

      // Verify: again < good < easy (hard can vary)
      expect(
        preview[fsrs.Rating.again]!.isBefore(preview[fsrs.Rating.good]!),
        isTrue,
      );
      expect(
        preview[fsrs.Rating.good]!.isBefore(preview[fsrs.Rating.easy]!),
        isTrue,
      );
    });
  });

  group('FSRSSchedulerService - Create Initial Progress', () {
    test('creates initial progress for new passage', () async {
      final companion = await service.createInitialProgress('new-passage-1');

      expect(companion.passageId.value, equals('new-passage-1'));
      expect(companion.masteryLevel.value, equals(0)); // New passage
      expect(companion.nextReview.present, isTrue);
      expect(companion.stability.present, isTrue);
      expect(companion.difficulty.present, isTrue);
    });

    test('creates different cards for different passages', () async {
      final companion1 = await service.createInitialProgress('passage-a');
      final companion2 = await service.createInitialProgress('passage-b');

      expect(companion1.passageId.value, equals('passage-a'));
      expect(companion2.passageId.value, equals('passage-b'));
      expect(
        companion1.passageId.value,
        isNot(equals(companion2.passageId.value)),
      );
    });

    test('creates consistent cards for same passage', () async {
      final companion1 = await service.createInitialProgress('same-passage');
      final companion2 = await service.createInitialProgress('same-passage');

      expect(companion1.passageId.value, equals(companion2.passageId.value));
      expect(
        companion1.masteryLevel.value,
        equals(companion2.masteryLevel.value),
      );
    });
  });
}
