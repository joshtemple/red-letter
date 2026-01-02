import 'package:flutter/foundation.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';

class PracticeController extends ValueNotifier<PracticeState> {
  final PassageRepository repository;

  PracticeController(
    Passage passage, {
    required this.repository,
    PracticeMode initialMode = PracticeMode.impression,
  }) : super(PracticeState.initial(passage, initialMode: initialMode));

  void advance([String? input]) {
    final currentMode = value.currentMode;
    final passageId = value.currentPassage.id;

    // Persist data based on the mode we are leaving or completing
    _persistProgress(currentMode, passageId, input);

    value = value.advanceMode();
    if (input != null) {
      value = value.updateInput(input);
    }
  }

  Future<void> _persistProgress(
    PracticeMode mode,
    String passageId,
    String? input,
  ) async {
    try {
      switch (mode) {
        case PracticeMode.impression:
          // Just ensure progress exists
          final existing = await repository.getProgress(passageId);
          if (existing == null) {
            await repository.createProgress(passageId);
          }
          break;
        case PracticeMode.reflection:
          if (input != null && input.isNotEmpty) {
            await repository.updateSemanticReflection(passageId, input);
          }
          break;
        case PracticeMode.scaffolding:
        case PracticeMode.prompted:
          // Update mastery level if successful?
          // For now, we just ensure mapped progress.
          // Real SRS logic would go here or at the end of session.
          await repository.updateMasteryLevel(passageId, 1); // Mark as learning
          break;
        case PracticeMode.reconstruction:
          // Final mode, marked as mastered for this session
          await repository.updateMasteryLevel(passageId, 3); // Mark as mastered
          break;
      }
    } catch (e) {
      debugPrint('Error persisting progress: $e');
    }
  }

  void reset() {
    value = value.reset();
  }
}
