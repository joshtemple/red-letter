import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';

void main() {
  group('PracticeState', () {
    late Passage testPassage;

    setUp(() {
      testPassage = Passage.fromText(
        id: 'mat-5-44',
        text: 'Love your enemies',
        reference: 'Matthew 5:44',
      );
    });

    test('should create initial state correctly', () {
      final state = PracticeState.initial(testPassage);

      expect(state.currentPassage, testPassage);
      expect(state.currentMode, PracticeMode.impression);
      expect(state.userInput, '');
      expect(state.completedModes.isEmpty, true);
      expect(state.isComplete, false);
    });

    test('should advance through modes correctly', () {
      var state = PracticeState.initial(testPassage);

      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.reflection);
      expect(state.completedModes.contains(PracticeMode.impression), true);

      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.scaffolding);
      expect(state.completedModes.contains(PracticeMode.reflection), true);

      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.prompted);

      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.reconstruction);
    });

    test('should clear user input when advancing mode', () {
      var state = PracticeState.initial(testPassage);
      state = state.updateInput('some input');

      expect(state.userInput, 'some input');

      state = state.advanceMode();
      expect(state.userInput, '');
    });

    test('should detect completion correctly', () {
      var state = PracticeState.initial(testPassage);

      expect(state.isComplete, false);

      for (var i = 0; i < PracticeMode.values.length; i++) {
        state = state.advanceMode();
      }

      expect(state.isComplete, true);
    });

    test('should reset state correctly', () {
      var state = PracticeState.initial(testPassage);
      state = state.advanceMode();
      state = state.advanceMode();
      state = state.updateInput('test input');

      state = state.reset();

      expect(state.currentMode, PracticeMode.impression);
      expect(state.userInput, '');
      expect(state.completedModes.isEmpty, true);
      expect(state.currentPassage, testPassage);
    });

    test('should update input correctly', () {
      final state = PracticeState.initial(testPassage);
      final updated = state.updateInput('Love your');

      expect(updated.userInput, 'Love your');
      expect(state.userInput, '');
    });

    test('should track elapsed time', () async {
      final state = PracticeState.initial(testPassage);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(state.elapsedTime.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('should implement copyWith correctly', () {
      final state = PracticeState.initial(testPassage);
      final copied = state.copyWith(
        currentMode: PracticeMode.scaffolding,
        userInput: 'test',
      );

      expect(copied.currentMode, PracticeMode.scaffolding);
      expect(copied.userInput, 'test');
      expect(copied.currentPassage, state.currentPassage);
      expect(copied.startTime, state.startTime);
    });

    test('should have readable toString', () {
      final state = PracticeState.initial(testPassage);
      final string = state.toString();

      expect(string, contains('PracticeState'));
      expect(string, contains('impression'));
    });
  });
}
