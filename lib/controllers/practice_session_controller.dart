import 'dart:math';

import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/models/practice_mode.dart';

class PracticeSessionController {
  final Random _random = Random();

  /// selects a random passage to practice from the list of available passages.
  ///
  /// Logic:
  /// - Filters for passages that are NOT effectively mastered (Level 5+) AND due for review?
  /// - For now, we simplify: Pick ANY random passage.
  ///   (Optimization: prioritize lower levels or "Due" items later with SRS).
  PassageWithProgress? selectRandomPassage(List<PassageWithProgress> passages) {
    if (passages.isEmpty) return null;

    // Simple random selection for M1/M2 MVP
    final index = _random.nextInt(passages.length);
    return passages[index];
  }

  /// Deteremines the correct practice mode based on mastery level.
  ///
  /// Mappings:
  /// 0 -> Impression
  /// 1 -> Reflection
  /// 2 -> Scaffolding
  /// 3 -> Prompted
  /// 4 -> Reconstruction
  /// 5+ -> Reconstruction (Mastered, but still reconstruct for review)
  PracticeMode getModeForLevel(int masteryLevel) {
    switch (masteryLevel) {
      case 0:
        return PracticeMode.impression;
      case 1:
        return PracticeMode.reflection;
      case 2:
        return PracticeMode.scaffolding;
      case 3:
        return PracticeMode.prompted;
      case 4:
      default:
        // Level 5+ stays at Reconstruction for maintenance
        return PracticeMode.reconstruction;
    }
  }
}
