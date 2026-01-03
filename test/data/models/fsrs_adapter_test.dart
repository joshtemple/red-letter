import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/models/fsrs_adapter.dart';

void main() {
  group('FSRSAdapter - UserProgress to FSRS Card Conversion', () {
    test('converts UserProgress with Learning state', () {
      final progress = UserProgress(
        id: 1,
        passageId: 'mat-5-44',
        masteryLevel: 1,
        state: 0, // Learning
        step: 0,
        stability: 1.5,
        difficulty: 6.0,
        lastReviewed: DateTime(2024, 1, 1),
        nextReview: DateTime(2024, 1, 2),
        semanticReflection: null,
        lastSync: null,
      );

      final card = FSRSAdapter.toFSRSCard(progress, passageId: 'mat-5-44');

      expect(card.state, equals(fsrs.State.learning));
      expect(card.step, equals(0));
      expect(card.stability, equals(1.5));
      expect(card.difficulty, equals(6.0));
      expect(card.due, equals(DateTime(2024, 1, 2)));
      expect(card.lastReview, equals(DateTime(2024, 1, 1)));
      expect(card.cardId, equals('mat-5-44'.hashCode));
    });

    test('converts UserProgress with Review state', () {
      final progress = UserProgress(
        id: 2,
        passageId: 'jhn-3-16',
        masteryLevel: 3,
        state: 1, // Review
        step: null,
        stability: 14.5,
        difficulty: 4.2,
        lastReviewed: DateTime(2024, 1, 10),
        nextReview: DateTime(2024, 1, 24),
        semanticReflection: 'God loves the world',
        lastSync: null,
      );

      final card = FSRSAdapter.toFSRSCard(progress, passageId: 'jhn-3-16');

      expect(card.state, equals(fsrs.State.review));
      expect(card.step, isNull);
      expect(card.stability, equals(14.5));
      expect(card.difficulty, equals(4.2));
      expect(card.due, equals(DateTime(2024, 1, 24)));
      expect(card.lastReview, equals(DateTime(2024, 1, 10)));
    });

    test('converts UserProgress with Relearning state', () {
      final progress = UserProgress(
        id: 3,
        passageId: 'rom-8-28',
        masteryLevel: 1,
        state: 2, // Relearning
        step: 0,
        stability: 3.0,
        difficulty: 7.5,
        lastReviewed: DateTime(2024, 1, 5),
        nextReview: DateTime(2024, 1, 6),
        semanticReflection: null,
        lastSync: null,
      );

      final card = FSRSAdapter.toFSRSCard(progress, passageId: 'rom-8-28');

      expect(card.state, equals(fsrs.State.relearning));
      expect(card.step, equals(0));
    });

    test('handles null lastReviewed and nextReview', () {
      final progress = UserProgress(
        id: 4,
        passageId: 'mat-6-9',
        masteryLevel: 0,
        state: 0,
        step: 0,
        stability: 0.0,
        difficulty: 5.0,
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
      expect(companion.state.value, equals(0)); // Learning = 0
      expect(companion.step.value, equals(0));
      expect(companion.stability.value, equals(1.0));
      expect(companion.difficulty.value, equals(5.0));
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

      expect(companion.masteryLevel.value, equals(2)); // Review state
      expect(companion.state.value, equals(1)); // Review = 1
      expect(companion.step.value, isNull);
      expect(companion.stability.value, equals(14.5));
    });

    test('converts Relearning state card to UserProgress companion', () {
      final card = fsrs.Card(
        cardId: 789,
        state: fsrs.State.relearning,
        step: 0,
        stability: 2.5,
        difficulty: 8.0,
        due: DateTime(2024, 1, 15),
        lastReview: DateTime(2024, 1, 14),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'rom-8-28',
        card: card,
      );

      expect(companion.masteryLevel.value, equals(1)); // Relearning → Learning level
      expect(companion.state.value, equals(2)); // Relearning = 2
      expect(companion.step.value, equals(0));
    });

    test('allows custom mastery level override', () {
      final card = fsrs.Card(
        cardId: 999,
        state: fsrs.State.review,
        step: null,
        stability: 30.0,
        difficulty: 2.0,
        due: DateTime.now(),
        lastReview: DateTime.now(),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'test',
        card: card,
        customMasteryLevel: 4, // Locked-in
      );

      expect(companion.masteryLevel.value, equals(4));
    });

    test('clamps infinite stability values', () {
      final card = fsrs.Card(
        cardId: 111,
        state: fsrs.State.review,
        step: null,
        stability: double.infinity,
        difficulty: 5.0,
        due: DateTime.now(),
        lastReview: DateTime.now(),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'test',
        card: card,
      );

      expect(companion.stability.value, equals(0.0)); // Clamped to 0
    });
  });

  group('FSRSAdapter - Performance Rating Conversion', () {
    test('converts performance 0-1 to Rating.again', () {
      expect(FSRSAdapter.performanceToRating(0), equals(fsrs.Rating.again));
      expect(FSRSAdapter.performanceToRating(1), equals(fsrs.Rating.again));
    });

    test('converts performance 2 to Rating.hard', () {
      expect(FSRSAdapter.performanceToRating(2), equals(fsrs.Rating.hard));
    });

    test('converts performance 3 to Rating.good', () {
      expect(FSRSAdapter.performanceToRating(3), equals(fsrs.Rating.good));
    });

    test('converts performance 4 to Rating.easy', () {
      expect(FSRSAdapter.performanceToRating(4), equals(fsrs.Rating.easy));
    });

    test('handles out-of-range performance gracefully', () {
      expect(FSRSAdapter.performanceToRating(5), equals(fsrs.Rating.good));
      expect(FSRSAdapter.performanceToRating(-1), equals(fsrs.Rating.good));
    });
  });

  group('FSRSAdapter - Rating to Performance Conversion', () {
    test('converts Rating.again to performance 0', () {
      expect(FSRSAdapter.ratingToPerformance(fsrs.Rating.again), equals(0));
    });

    test('converts Rating.hard to performance 2', () {
      expect(FSRSAdapter.ratingToPerformance(fsrs.Rating.hard), equals(2));
    });

    test('converts Rating.good to performance 3', () {
      expect(FSRSAdapter.ratingToPerformance(fsrs.Rating.good), equals(3));
    });

    test('converts Rating.easy to performance 4', () {
      expect(FSRSAdapter.ratingToPerformance(fsrs.Rating.easy), equals(4));
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
