import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:red_letter/data/models/session_metrics.dart';

void main() {
  group('SessionMetrics - Basic Calculations', () {
    test('calculates CPM correctly', () {
      final metrics = SessionMetrics(
        passageText: 'The quick brown fox',
        userInput: 'The quick brown fox',
        durationMs: 60000, // 1 minute
        levenshteinDistance: 0,
      );

      // 19 characters in 1 minute = 19 CPM
      expect(metrics.cpm, equals(19.0));
    });

    test('calculates WPM correctly', () {
      final metrics = SessionMetrics(
        passageText: 'The quick brown fox jumps',
        userInput: 'The quick brown fox jumps',
        durationMs: 30000, // 30 seconds = 0.5 minutes
        levenshteinDistance: 0,
      );

      // 25 characters in 0.5 minutes = 50 CPM = 10 WPM
      expect(metrics.wpm, equals(10.0));
    });

    test('calculates perfect accuracy', () {
      final metrics = SessionMetrics(
        passageText: 'Hello world',
        userInput: 'Hello world',
        durationMs: 10000,
        levenshteinDistance: 0,
      );

      expect(metrics.accuracy, equals(1.0));
    });

    test('calculates partial accuracy', () {
      final metrics = SessionMetrics(
        passageText: 'Hello world', // 11 characters
        userInput: 'Hello worle', // 1 character difference
        durationMs: 10000,
        levenshteinDistance: 1,
      );

      // (11 - 1) / 11 = 10/11 ≈ 0.909
      expect(metrics.accuracy, closeTo(0.909, 0.001));
    });

    test('calculates zero accuracy for completely wrong input', () {
      final metrics = SessionMetrics(
        passageText: 'ABC', // 3 characters
        userInput: 'XYZ',
        durationMs: 10000,
        levenshteinDistance: 3, // All 3 characters different
      );

      expect(metrics.accuracy, equals(0.0));
    });

    test('handles empty passage gracefully', () {
      final metrics = SessionMetrics(
        passageText: '',
        userInput: '',
        durationMs: 10000,
        levenshteinDistance: 0,
      );

      expect(metrics.accuracy, equals(1.0));
    });
  });

  group('SessionMetrics - Recall Quality', () {
    test('calculates high quality for fast and accurate', () {
      final metrics = SessionMetrics(
        passageText: 'A' * 400, // 400 characters
        userInput: 'A' * 400,
        durationMs: 30000, // 30 seconds = 800 CPM = 160 WPM (excellent)
        levenshteinDistance: 0,
      );

      // Accuracy: 1.0 (perfect)
      // Speed: 160 WPM / 80 = 2.0, clamped to 1.0
      // Quality: (1.0 * 0.7) + (1.0 * 0.3) = 1.0
      expect(metrics.recallQuality, equals(1.0));
    });

    test('calculates medium quality for moderate performance', () {
      final metrics = SessionMetrics(
        passageText: 'A' * 200, // 200 characters
        userInput: 'A' * 190 + 'B' * 10, // 10 errors
        durationMs: 60000, // 1 minute = 200 CPM = 40 WPM (baseline)
        levenshteinDistance: 10,
      );

      // Accuracy: (200 - 10) / 200 = 0.95
      // Speed: 40 WPM / 80 = 0.5
      // Quality: (0.95 * 0.7) + (0.5 * 0.3) = 0.665 + 0.15 = 0.815
      expect(metrics.recallQuality, closeTo(0.815, 0.001));
    });

    test('calculates low quality for poor performance', () {
      final metrics = SessionMetrics(
        passageText: 'A' * 100,
        userInput: 'A' * 60 + 'B' * 40, // 40 errors
        durationMs: 120000, // 2 minutes = 50 CPM = 10 WPM (very slow)
        levenshteinDistance: 40,
      );

      // Accuracy: (100 - 40) / 100 = 0.6
      // Speed: 10 WPM / 80 = 0.125
      // Quality: (0.6 * 0.7) + (0.125 * 0.3) = 0.42 + 0.0375 = 0.4575
      expect(metrics.recallQuality, closeTo(0.458, 0.001));
    });
  });

  group('SessionMetrics - FSRS Rating Mapping', () {
    test('maps perfect performance to Rating.easy', () {
      final metrics = SessionMetrics(
        passageText: 'For God so loved the world',
        userInput: 'For God so loved the world',
        durationMs: 3000, // Fast: ~500 CPM = 100 WPM
        levenshteinDistance: 0,
      );

      expect(metrics.toFSRSRating(), equals(fsrs.Rating.easy));
    });

    test('maps excellent performance to Rating.easy', () {
      final metrics = SessionMetrics(
        passageText: 'Love your enemies and pray for those who persecute you',
        userInput: 'Love your enemies and pray for those who persicute you', // 1 minor typo
        durationMs: 8000, // Fast: ~400 CPM = 80 WPM
        levenshteinDistance: 1,
      );

      // Accuracy: ~98% (near-perfect), Speed: 80 WPM (fast) = Easy
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.easy));
    });

    test('maps struggling performance to Rating.hard', () {
      final metrics = SessionMetrics(
        passageText: 'Blessed are the peacemakers',
        userInput: 'Blessed ar the peacemakers', // Missing 'e'
        durationMs: 10000, // Slow: ~160 CPM = 32 WPM
        levenshteinDistance: 1,
      );

      // Accuracy: ~96%, but slow speed
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.hard));
    });

    test('maps very slow typing to Rating.again', () {
      final metrics = SessionMetrics(
        passageText: 'Do not worry about tomorrow',
        userInput: 'Do not worry about tomorrow',
        durationMs: 40000, // Very slow: ~42 CPM = 8.4 WPM
        levenshteinDistance: 0,
      );

      // Perfect accuracy but extremely slow = struggling to recall
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.again));
    });

    test('maps low accuracy to Rating.again', () {
      final metrics = SessionMetrics(
        passageText: 'The Lord is my shepherd',
        userInput: 'The lord iz my sheperd', // Multiple errors
        durationMs: 5000, // Normal speed
        levenshteinDistance: 8, // ~35% error rate
      );

      // Accuracy < 70% threshold
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.again));
    });

    test('maps borderline hard performance correctly', () {
      final metrics = SessionMetrics(
        passageText: 'A' * 100,
        userInput: 'A' * 85 + 'B' * 15, // 15 errors = 85% accuracy
        durationMs: 15000, // ~400 CPM = 80 WPM
        levenshteinDistance: 15,
      );

      // Accuracy: 85% (on the edge), good speed
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.good));
    });

    test('maps borderline again performance correctly', () {
      final metrics = SessionMetrics(
        passageText: 'A' * 100,
        userInput: 'A' * 69 + 'B' * 31, // 31 errors = 69% accuracy
        durationMs: 10000, // Decent speed
        levenshteinDistance: 31,
      );

      // Accuracy: 69% (just below 70% threshold)
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.again));
    });
  });

  group('SessionMetrics - Edge Cases', () {
    test('handles zero duration gracefully', () {
      final metrics = SessionMetrics(
        passageText: 'Test',
        userInput: 'Test',
        durationMs: 0,
        levenshteinDistance: 0,
      );

      expect(metrics.cpm, equals(0.0));
      expect(metrics.wpm, equals(0.0));
      // Zero WPM should trigger Rating.again
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.again));
    });

    test('handles very short passages', () {
      final metrics = SessionMetrics(
        passageText: 'Hi',
        userInput: 'Hi',
        durationMs: 500, // Half second
        levenshteinDistance: 0,
      );

      expect(metrics.accuracy, equals(1.0));
      // 2 chars in 0.00833 min = 240 CPM = 48 WPM (good but not excellent)
      expect(metrics.wpm, closeTo(48.0, 1.0));
    });

    test('handles very long passages', () {
      final longText = 'A' * 1000;
      final metrics = SessionMetrics(
        passageText: longText,
        userInput: longText,
        durationMs: 60000, // 1 minute
        levenshteinDistance: 0,
      );

      // 1000 chars / 1 min = 1000 CPM = 200 WPM (very fast)
      expect(metrics.wpm, equals(200.0));
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.easy));
    });

    test('handles levenshtein distance larger than passage', () {
      final metrics = SessionMetrics(
        passageText: 'ABC',
        userInput: 'XYZDEF', // Longer and completely different
        durationMs: 5000,
        levenshteinDistance: 6, // Larger than passage length
      );

      // Should handle gracefully, possibly negative accuracy
      expect(metrics.accuracy, lessThanOrEqualTo(0.0));
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.again));
    });
  });

  group('SessionMetrics - Real-World Scenarios', () {
    test('scenario: first-time learning (slow but accurate)', () {
      final metrics = SessionMetrics(
        passageText: 'Love is patient, love is kind',
        userInput: 'Love is patient, love is kind',
        durationMs: 17000, // Slow: ~102 CPM = 20.4 WPM
        levenshteinDistance: 0,
      );

      // Perfect accuracy but slow (just above 20 WPM) = Hard (learning)
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.hard));
    });

    test('scenario: recently learned (fast with minor typos)', () {
      final metrics = SessionMetrics(
        passageText: 'Do not be anxious about anything',
        userInput: 'Do not be anxius about anything', // 1 typo
        durationMs: 6000, // Fast: ~320 CPM = 64 WPM
        levenshteinDistance: 1,
      );

      // High accuracy (97%), fast speed (64 WPM) = Easy (nearly mastered)
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.easy));
    });

    test('scenario: well-mastered (effortless recall)', () {
      final metrics = SessionMetrics(
        passageText: 'The Lord is my shepherd, I shall not want',
        userInput: 'The Lord is my shepherd, I shall not want',
        durationMs: 4000, // Very fast: ~640 CPM = 128 WPM
        levenshteinDistance: 0,
      );

      // Perfect + fast = Easy (mastered)
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.easy));
    });

    test('scenario: struggling to remember (many pauses and errors)', () {
      final metrics = SessionMetrics(
        passageText: 'Rejoice in the Lord always',
        userInput: 'Rejoic in the Lor always', // Missing letters
        durationMs: 25000, // Very slow: ~60 CPM = 12 WPM
        levenshteinDistance: 3,
      );

      // Low accuracy and slow = Again (forgotten)
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.again));
    });

    test('scenario: speed-reader (fast but sloppy)', () {
      final metrics = SessionMetrics(
        passageText: 'Therefore do not worry about tomorrow',
        userInput: 'Therfore do not wory about tommorow', // Multiple typos
        durationMs: 3000, // Very fast: ~760 CPM = 152 WPM
        levenshteinDistance: 4,
      );

      // Fast (152 WPM) but errors reduce accuracy to ~89%
      // 89% > 85% AND 152 > 30 = Good
      expect(metrics.toFSRSRating(), equals(fsrs.Rating.good));
    });
  });

  group('SessionMetrics - toString and equality', () {
    test('toString provides readable output', () {
      final metrics = SessionMetrics(
        passageText: 'Test passage',
        userInput: 'Test passage',
        durationMs: 10000,
        levenshteinDistance: 0,
      );

      final str = metrics.toString();
      expect(str, contains('accuracy'));
      expect(str, contains('wpm'));
      expect(str, contains('quality'));
      expect(str, contains('rating'));
    });

    test('equality works correctly', () {
      final metrics1 = SessionMetrics(
        passageText: 'Same',
        userInput: 'Same',
        durationMs: 5000,
        levenshteinDistance: 0,
      );

      final metrics2 = SessionMetrics(
        passageText: 'Same',
        userInput: 'Same',
        durationMs: 5000,
        levenshteinDistance: 0,
      );

      final metrics3 = SessionMetrics(
        passageText: 'Different',
        userInput: 'Different',
        durationMs: 5000,
        levenshteinDistance: 0,
      );

      expect(metrics1, equals(metrics2));
      expect(metrics1, isNot(equals(metrics3)));
    });

    test('hashCode is consistent', () {
      final metrics = SessionMetrics(
        passageText: 'Test',
        userInput: 'Test',
        durationMs: 1000,
        levenshteinDistance: 0,
      );

      expect(metrics.hashCode, equals(metrics.hashCode));
    });
  });
}
