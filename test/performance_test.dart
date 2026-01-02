import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/models/word_occlusion.dart';

void main() {
  group('Performance Benchmarks', () {
    // A reasonably long passage to stress test
    final longText =
        'In the beginning was the Word, and the Word was with God, and the Word was God. ' *
        5;
    // ~80 words * 5 = 400 words. A standard verse is usually <50 words.

    final passage = Passage.fromText(
      id: 'perf-test',
      text: longText,
      reference: 'John 1:1',
    );

    test('WordOcclusion.checkInput latency (simulating keystroke)', () {
      final occlusion = WordOcclusion.generate(passage: passage);
      final stopWatch = Stopwatch()..start();

      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        // Simulate typing "the" which appears many times
        occlusion.checkInput('the');
      }

      stopWatch.stop();
      final avgMicros = stopWatch.elapsedMicroseconds / iterations;

      print(
        'Average WordOcclusion.checkInput time: ${avgMicros.toStringAsFixed(2)} µs',
      );

      // Requirement: 8-16ms (8000-16000 µs).
      // We aim for < 1000 µs (1ms) to be extremely safe for logic.
      expect(
        avgMicros,
        lessThan(1000),
        reason: 'Logic should be well under 1ms',
      );
    });

    test('PassageValidator.isStrictMatch latency', () {
      final stopWatch = Stopwatch()..start();

      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        PassageValidator.isStrictMatch(longText, longText);
      }

      stopWatch.stop();
      final avgMicros = stopWatch.elapsedMicroseconds / iterations;

      print(
        'Average PassageValidator.isStrictMatch time: ${avgMicros.toStringAsFixed(2)} µs',
      );
      expect(avgMicros, lessThan(1000));
    });

    test('PassageValidator.isLenientMatch latency', () {
      final stopWatch = Stopwatch()..start();

      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        PassageValidator.isLenientMatch(longText, longText.toUpperCase());
      }

      stopWatch.stop();
      final avgMicros = stopWatch.elapsedMicroseconds / iterations;

      print(
        'Average PassageValidator.isLenientMatch time: ${avgMicros.toStringAsFixed(2)} µs',
      );
      expect(avgMicros, lessThan(1000));
    });
  });
}
