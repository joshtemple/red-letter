import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/models/fsrs_adapter.dart';

import 'package:fsrs/fsrs.dart' as fsrs;

void main() {
  group('Mastery Logic - Stability to Mastery Level Mapping', () {
    // Helper to test mapping via toUserProgressCompanion
    int getMasteryForStability(double stability) {
      final card = fsrs.Card(
        cardId: 1,
        state: fsrs.State.review,
        step: null,
        stability: stability, // The key variable
        difficulty: 5.0,
        due: DateTime.now(),
        lastReview: DateTime.now(),
      );

      final companion = FSRSAdapter.toUserProgressCompanion(
        passageId: 'test',
        card: card,
      );

      return companion.masteryLevel.value;
    }

    test('Stability <= 0 -> Mastery 0 (New)', () {
      expect(getMasteryForStability(0.0), equals(0));
      expect(
        getMasteryForStability(-1.0),
        equals(0),
      ); // Should clamp to 0 physically, but logic handles <=0
    });

    test('0 < Stability <= 3 -> Mastery 1 (Acquired)', () {
      expect(getMasteryForStability(0.1), equals(1));
      expect(getMasteryForStability(1.0), equals(1));
      expect(getMasteryForStability(3.0), equals(1));
    });

    test('3 < Stability <= 14 -> Mastery 2 (Solid)', () {
      expect(getMasteryForStability(3.1), equals(2));
      expect(getMasteryForStability(7.0), equals(2));
      expect(getMasteryForStability(14.0), equals(2));
    });

    test('14 < Stability <= 90 -> Mastery 3 (Strong)', () {
      expect(getMasteryForStability(14.1), equals(3));
      expect(getMasteryForStability(30.0), equals(3));
      expect(getMasteryForStability(90.0), equals(3));
    });

    test('Stability > 90 -> Mastery 4 (Mastered)', () {
      expect(getMasteryForStability(90.1), equals(4));
      expect(getMasteryForStability(365.0), equals(4));
    });
  });
}
