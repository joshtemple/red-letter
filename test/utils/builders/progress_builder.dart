import 'package:red_letter/data/database/app_database.dart';

/// Test Data Builder for [UserProgress] model.
///
/// Usage:
/// ```dart
/// final progress = ProgressBuilder()
///   .forPassage('mat-5-44')
///   .atMasteryLevel(2)
///   .build();
/// ```
class ProgressBuilder {
  int _id = 1;
  String _passageId = 'test-passage-id';
  int _masteryLevel = 0;
  int _state = 0; // Learning
  int? _step = 0;
  double _stability = 2.0; // Default to non-zero to safe-guard against FSRS NaN
  double _difficulty = 5.0;
  DateTime? _lastReviewed;
  DateTime? _nextReview;
  String? _semanticReflection;
  DateTime? _lastSync;

  ProgressBuilder withId(int id) {
    _id = id;
    return this;
  }

  ProgressBuilder forPassage(String passageId) {
    _passageId = passageId;
    return this;
  }

  ProgressBuilder atMasteryLevel(int level) {
    _masteryLevel = level;
    return this;
  }

  ProgressBuilder withState(int state) {
    _state = state;
    return this;
  }

  ProgressBuilder withStep(int? step) {
    _step = step;
    return this;
  }

  ProgressBuilder withStability(double stability) {
    _stability = stability;
    return this;
  }

  ProgressBuilder withDifficulty(double difficulty) {
    _difficulty = difficulty;
    return this;
  }

  ProgressBuilder reviewedAt(DateTime? lastReviewed) {
    _lastReviewed = lastReviewed;
    return this;
  }

  ProgressBuilder dueAt(DateTime? nextReview) {
    _nextReview = nextReview;
    return this;
  }

  ProgressBuilder withReflection(String? reflection) {
    _semanticReflection = reflection;
    return this;
  }

  ProgressBuilder syncedAt(DateTime? lastSync) {
    _lastSync = lastSync;
    return this;
  }

  UserProgress build() {
    return UserProgress(
      id: _id,
      passageId: _passageId,
      masteryLevel: _masteryLevel,
      state: _state,
      step: _step,
      stability: _stability,
      difficulty: _difficulty,
      lastReviewed: _lastReviewed,
      nextReview: _nextReview,
      semanticReflection: _semanticReflection,
      lastSync: _lastSync,
    );
  }
}
