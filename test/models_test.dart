import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';

void main() {
  group('Passage Tests', () {
    test('should create instance from text', () {
      final p = Passage.fromText(
        id: '1',
        text: 'Jesus wept.',
        reference: 'John 11:35',
      );
      expect(p.id, '1');
      expect(p.words, ['Jesus', 'wept.']);
    });
  });

  group('PracticeState Tests', () {
    test('should progress through modes', () {
      final p = Passage.fromText(
        id: '1',
        text: 'Test',
        reference: 'Ref',
      );
      var state = PracticeState.initial(p);

      expect(state.currentMode, PracticeMode.impression);
      
      // Advance to Reflection
      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.reflection);
      expect(state.completedModes, contains(PracticeMode.impression));

      // Advance to Scaffolding
      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.scaffolding);

       // Advance to Prompted
      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.prompted);

       // Advance to Reconstruction
      state = state.advanceMode();
      expect(state.currentMode, PracticeMode.reconstruction);

       // Finish
      state = state.advanceMode();
      
      expect(state.currentMode, PracticeMode.reconstruction);
      expect(state.completedModes.length, 5);
      expect(state.completedModes, containsAll(PracticeMode.values));
    });

    test('reset should return to initial state', () {
       final p = Passage.fromText(id: '1', text: 'Test', reference: 'Ref');
       var state = PracticeState.initial(p);
       state = state.advanceMode(); // Reflection
       
       state = state.reset();
       expect(state.currentMode, PracticeMode.impression);
       expect(state.completedModes, isEmpty);
    });
  });
}
