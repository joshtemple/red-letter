import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/services/fsrs_scheduler_service.dart';

import '../utils/builders/progress_builder.dart';

void main() {
  late FSRSSchedulerService service;

  setUp(() {
    service = FSRSSchedulerService();
  });

  group('FSRSSchedulerService', () {
    test('createInitialProgress returns valid learning card', () async {
      final companion = await service.createInitialProgress('new-passage-1');

      expect(companion.passageId.value, equals('new-passage-1'));
      expect(companion.masteryLevel.value, equals(0)); // New passage
      expect(companion.nextReview.present, isTrue);
      // Verify FSRS defaults are set
      expect(companion.stability.present, isTrue);
      expect(companion.difficulty.present, isTrue);
    });

    test('reviewPassage updates progress correctly for Good rating', () {
      final progress = ProgressBuilder()
          .forPassage('mat-5-44')
          .withState(0) // Learning
          .withStability(1.0)
          .withDifficulty(5.0)
          .reviewedAt(DateTime(2024, 1, 1))
          .dueAt(DateTime(2024, 1, 1))
          .build();

      final companion = service.reviewPassage(
        passageId: 'mat-5-44',
        progress: progress,
        rating: fsrs.Rating.good,
      );

      expect(companion.passageId.value, equals('mat-5-44'));
      expect(companion.nextReview.present, isTrue);
      expect(companion.lastReviewed.present, isTrue);
      // Basic check that scheduling moved forward
      expect(companion.nextReview.value!.isAfter(DateTime(2024, 1, 1)), isTrue);
    });

    test('reviewPassage updates progress for Again (relearning)', () {
      final progress = ProgressBuilder()
          .forPassage('jhn-3-16')
          .withState(1) // Review
          .withStability(14.0)
          .withDifficulty(4.0)
          .reviewedAt(DateTime(2024, 1, 10))
          .dueAt(DateTime(2024, 1, 24))
          .build();

      final companion = service.reviewPassage(
        passageId: 'jhn-3-16',
        progress: progress,
        rating: fsrs.Rating.again,
      );

      // Stability should decrease on failure
      expect(companion.stability.present, isTrue);
      expect(companion.stability.value, lessThan(progress.stability));
    });

    // Removed test: reviewPassage accepts custom mastery level override

    test(
      'getRetrievability returns null for null nextReview (new/unreviewed)',
      () {
        final progress = ProgressBuilder()
            .forPassage('test-4')
            .reviewedAt(null) // Never reviewed
            .build();

        final retrievability = service.getRetrievability(
          progress: progress,
          passageId: 'test-4',
        );

        expect(retrievability, isNull);
      },
    );

    test('previewNextReviewDates returns all rating options', () {
      final progress = ProgressBuilder()
          .forPassage('test-8')
          .withState(1) // Review
          .withStability(5.0) // Must be > 0
          .withDifficulty(5.0)
          .reviewedAt(DateTime.now())
          .build();

      final preview = service.previewNextReviewDates(
        progress: progress,
        passageId: 'test-8',
      );

      expect(preview.keys, containsAll(fsrs.Rating.values));
      expect(preview[fsrs.Rating.good], isA<DateTime>());
    });
  });
}
