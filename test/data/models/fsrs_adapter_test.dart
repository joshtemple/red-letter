import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/models/fsrs_adapter.dart';

void main() {
  group('FSRSAdapter - UserProgress to FSRS Card Conversion', () {
    test('converts UserProgress with Learning state (mastery level 0-1)',
        () {
      final progress = UserProgress(
        id: 1,
        passageId: 'mat-5-44',
        masteryLevel: 1,
        interval: 0,
        repetitionCount: 0,
        easeFactor: 250,
        lastReviewed: DateTime(2024, 1, 1),
        nextReview: DateTime(2024, 1, 2),
        semanticReflection: null,
        lastSync: null,
      );

      final card = FSRSAdapter.toFSRSCard(progress, passageId: 'mat-5-44');

      expect(card.state, equals(fsrs.State.learning));
      expect(card.step, equals(0));
      expect(card.due, equals(DateTime(2024, 1, 2)));
      expect(card.lastReview, equals(DateTime(2024, 1, 1)));
      expect(card.cardId, equals('mat-5-44'.hashCode));
    });

    test('converts UserProgress with Review state (mastery level 2+)', () {
      final progress = UserProgress(
        id: 2,
        passageId: 'jhn-3-16',
        masteryLevel: 3,
        interval: 7,
        repetitionCount: 5,
        easeFactor: 260,
        lastReviewed: DateTime(2024, 1, 10),
        nextReview: DateTime(2024, 1, 17),
        semanticReflection: 'God loves the world',
        lastSync: null,
      );

      final card = FSRSAdapter.toFSRSCard(progress, passageId: 'jhn-3-16');

      expect(card.state, equals(fsrs.State.review));
      expect(card.step, isNull); // Review state has no step
      expect(card.stability, equals(7.0)); // Derived from interval
      expect(card.due, equals(DateTime(2024, 1, 17)));
      expect(card.lastReview, equals(DateTime(2024, 1, 10)));
    });

    test('handles null lastReviewed and nextReview', () {
      final progress = UserProgress(
        id: 3,
        passageId: 'mat-6-9',
        masteryLevel: 0,
        interval: 0,
        repetitionCount: 0,
        easeFactor: 250,
        lastReviewed: null,
        nextReview: null,
        semanticReflection: null,
        lastSync: null,
      );

      final card = FSRSAdapter.toFSRSCard(progress, passageId: 'mat-6-9');

      expect(card.state, equals(fsrs.State.learning));
      expect(card.lastReview, isNull);
      // nextReview is null, so due should default to now
      expect(
        card.due.difference(DateTime.now()).inMinutes.abs(),
        lessThan(1),
      );
    });

    test('converts easeFactor to FSRS difficulty correctly', () {
      // easeFactor 250 (2.5) should map to middle difficulty range
      final progress1 = UserProgress(
        id: 4,
        passageId: 'test-1',
        masteryLevel: 2,
        interval: 5,
        repetitionCount: 2,
        easeFactor: 250, // 2.5
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now(),
        semanticReflection: null,
        lastSync: null,
      );

      final card1 = FSRSAdapter.toFSRSCard(progress1, passageId: 'test-1');
      expect(card1.difficulty, isNotNull);
      expect(card1.difficulty!, inInclusiveRange(0.0, 10.0));

      // Lower easeFactor (harder) should map to higher difficulty
      final progress2 = UserProgress(
        id: 5,
        passageId: 'test-2',
        masteryLevel: 2,
        interval: 5,
        repetitionCount: 2,
        easeFactor: 130, // 1.3 (minimum)
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now(),
        semanticReflection: null,
        lastSync: null,
      );

      final card2 = FSRSAdapter.toFSRSCard(progress2, passageId: 'test-2');
      expect(card2.difficulty, greaterThan(card1.difficulty!));
    });
  });

  group('FSRSAdapter - FSRS Card to UserProgress Conversion', () {
    test('converts Learning state card to UserProgress companion', () {
      final card = fsrs.Card(
        cardId: 123,
        state: fsrs.State.learning,
        step: 0,
        stability: 1.0,
        difficulty: 5.0,
        due: DateTime(2024, 1, 5),
        lastReview: DateTime(2024, 1, 4),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'mat-5-44',
        card: card,
      );

      expect(companion.passageId.value, equals('mat-5-44'));
      expect(companion.masteryLevel.value, equals(1)); // Learning state
      expect(companion.interval.value, equals(1)); // Stability rounded
      expect(companion.nextReview.value, equals(DateTime(2024, 1, 5)));
      expect(companion.lastReviewed.value, equals(DateTime(2024, 1, 4)));
    });

    test('converts Review state card to UserProgress companion', () {
      final card = fsrs.Card(
        cardId: 456,
        state: fsrs.State.review,
        step: null,
        stability: 14.5,
        difficulty: 3.0,
        due: DateTime(2024, 1, 20),
        lastReview: DateTime(2024, 1, 5),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'jhn-3-16',
        card: card,
      );

      expect(companion.masteryLevel.value, equals(2)); // Review state minimum
      expect(companion.interval.value, equals(15)); // Stability rounded up
    });

    test('allows custom mastery level override', () {
      final card = fsrs.Card(
        cardId: 789,
        state: fsrs.State.review,
        step: null,
        stability: 30.0,
        difficulty: 2.0,
        due: DateTime.now(),
        lastReview: DateTime.now(),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'rom-8-28',
        card: card,
        customMasteryLevel: 4, // Locked-in
      );

      expect(companion.masteryLevel.value, equals(4));
    });

    test('calculates easeFactor from FSRS difficulty', () {
      final card = fsrs.Card(
        cardId: 999,
        state: fsrs.State.review,
        step: null,
        stability: 10.0,
        difficulty: 5.0, // Middle difficulty
        due: DateTime.now(),
        lastReview: DateTime.now(),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'test',
        card: card,
      );

      // Difficulty 5.0 should map back to easeFactor around 250
      // Allow wider range due to rounding and conversion approximations
      expect(companion.easeFactor.value, inInclusiveRange(150, 300));
    });
  });

  group('FSRSAdapter - Performance Rating Conversion', () {
    test('converts performance 0-1 to Rating.again', () {
      expect(
        FSRSAdapter.performanceToRating(0),
        equals(fsrs.Rating.again),
      );
      expect(
        FSRSAdapter.performanceToRating(1),
        equals(fsrs.Rating.again),
      );
    });

    test('converts performance 2 to Rating.hard', () {
      expect(
        FSRSAdapter.performanceToRating(2),
        equals(fsrs.Rating.hard),
      );
    });

    test('converts performance 3 to Rating.good', () {
      expect(
        FSRSAdapter.performanceToRating(3),
        equals(fsrs.Rating.good),
      );
    });

    test('converts performance 4 to Rating.easy', () {
      expect(
        FSRSAdapter.performanceToRating(4),
        equals(fsrs.Rating.easy),
      );
    });

    test('handles out-of-range performance gracefully', () {
      expect(
        FSRSAdapter.performanceToRating(5),
        equals(fsrs.Rating.good),
      ); // Default
      expect(
        FSRSAdapter.performanceToRating(-1),
        equals(fsrs.Rating.good),
      ); // Default
    });
  });

  group('FSRSAdapter - Rating to Performance Conversion', () {
    test('converts Rating.again to performance 0', () {
      expect(
        FSRSAdapter.ratingToPerformance(fsrs.Rating.again),
        equals(0),
      );
    });

    test('converts Rating.hard to performance 2', () {
      expect(
        FSRSAdapter.ratingToPerformance(fsrs.Rating.hard),
        equals(2),
      );
    });

    test('converts Rating.good to performance 3', () {
      expect(
        FSRSAdapter.ratingToPerformance(fsrs.Rating.good),
        equals(3),
      );
    });

    test('converts Rating.easy to performance 4', () {
      expect(
        FSRSAdapter.ratingToPerformance(fsrs.Rating.easy),
        equals(4),
      );
    });

    test('round-trip conversion preserves ratings', () {
      for (var performance in [0, 1, 2, 3, 4]) {
        final rating = FSRSAdapter.performanceToRating(performance);
        final backToPerformance = FSRSAdapter.ratingToPerformance(rating);

        // Note: 0 and 1 both map to Rating.again, so back-conversion gives 0
        if (performance == 1) {
          expect(backToPerformance, equals(0));
        } else {
          expect(backToPerformance, equals(performance));
        }
      }
    });
  });

  group('FSRSAdapter - New Card Creation', () {
    test('creates new card with correct passageId hash', () async {
      final card = await FSRSAdapter.createNewCard('mat-5-44');

      expect(card.cardId, equals('mat-5-44'.hashCode));
      expect(card.state, equals(fsrs.State.learning));
      // New cards may have step 0 or null initially
      // Stability and difficulty may be null until first review
      expect(card.due, isNotNull);
    });

    test('creates different cardIds for different passages', () async {
      final card1 = await FSRSAdapter.createNewCard('mat-5-44');
      final card2 = await FSRSAdapter.createNewCard('jhn-3-16');

      expect(card1.cardId, isNot(equals(card2.cardId)));
    });

    test('creates consistent cardIds for same passage', () async {
      final card1 = await FSRSAdapter.createNewCard('rom-8-28');
      final card2 = await FSRSAdapter.createNewCard('rom-8-28');

      expect(card1.cardId, equals(card2.cardId));
    });
  });
}
