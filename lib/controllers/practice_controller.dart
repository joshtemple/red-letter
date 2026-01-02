import 'package:flutter/foundation.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';

class PracticeController extends ValueNotifier<PracticeState> {
  PracticeController(
    Passage passage, {
    PracticeMode initialMode = PracticeMode.impression,
  }) : super(PracticeState.initial(passage, initialMode: initialMode));

  void advance([String? input]) {
    value = value.advanceMode();
    if (input != null) {
      value = value.updateInput(input);
    }
  }

  void reset() {
    value = value.reset();
  }
}
