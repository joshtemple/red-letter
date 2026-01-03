# Advanced Acquisition Ladder - Integration Guide

This document explains how to integrate the newly implemented Advanced Acquisition Ladder (M3) into the Red Letter practice engine.

## Overview

Epic `rl-2lt` implements a progressive scaffolding system with 3 rounds of increasing difficulty:

1. **Round 1**: Random word removal (1-2 content words per clause)
2. **Round 2**: Rotating clause deletion (hide entire clauses, one at a time)
3. **Round 3**: First-2-words scaffolding (show only first 2 words of each clause)

## Implementation Summary

### New Models Created

#### 1. `ClauseSegmentation` (`lib/models/clause_segmentation.dart`)

Segments passages into meaningful clauses based on punctuation (`,`, `.`, `:`, `;`, `!`, `?`).

```dart
final segmentation = ClauseSegmentation.fromPassage(passage);
print('Found ${segmentation.clauseCount} clauses');

// Access individual clauses
final firstClause = segmentation.clauses[0];
print('Clause: ${firstClause.text}');
print('Words: ${firstClause.wordIndices}');
```

#### 2. `ClozeOcclusion` (`lib/models/cloze_occlusion.dart`)

Manages word occlusion for all three rounds of the acquisition ladder.

```dart
// Round 1: Random word per clause
final round1 = ClozeOcclusion.randomWordPerClause(
  passage: passage,
  wordsPerClause: 1, // Hide 1-2 content words per clause
);

// Round 2: Rotating clause deletion
final round2 = ClozeOcclusion.rotatingClauseDeletion(
  passage: passage,
  clauseIndex: 0, // Hide first clause, rotate through all
);

// Round 3: First-2-words scaffolding
final round3 = ClozeOcclusion.firstTwoWordsScaffolding(
  passage: passage,
);
```

#### 3. `AcquisitionState` (`lib/models/acquisition_state.dart`)

Tracks progression through the acquisition ladder and handles failure/retry logic.

```dart
// Start at Round 1
var state = AcquisitionState.initial(totalClauses: 3);

// User succeeds, advance to next round
state = state.advance()!;

// User fails, step back to previous round
state = state.stepBack()!;

// Check completion
if (state.isComplete) {
  print('All rounds completed!');
}
```

### Refinements to Existing Screens

#### Impression Screen Enhancement

Added read-aloud encouragement prompt at the top of the screen:

```dart
Text(
  'Read this passage aloud twice',
  style: RedLetterTypography.body.copyWith(
    fontSize: 14,
    fontStyle: FontStyle.italic,
    color: RedLetterColors.textSecondary,
  ),
)
```

## Integration Steps

### 1. Update Scaffolding Screen

Replace the current `WordOcclusion` usage with `ClozeOcclusion` and `AcquisitionState`:

```dart
class _ScaffoldingScreenState extends State<ScaffoldingScreen> {
  late ClozeOcclusion _occlusion;
  late AcquisitionState _acquisitionState;

  @override
  void initState() {
    super.initState();

    final segmentation = ClauseSegmentation.fromPassage(widget.state.currentPassage);

    _acquisitionState = AcquisitionState.initial(
      totalClauses: segmentation.clauseCount,
    );

    _occlusion = _createOcclusionForCurrentRound();
  }

  ClozeOcclusion _createOcclusionForCurrentRound() {
    switch (_acquisitionState.currentLevel) {
      case AcquisitionLevel.randomWordPerClause:
        return ClozeOcclusion.randomWordPerClause(
          passage: widget.state.currentPassage,
          wordsPerClause: 1,
        );

      case AcquisitionLevel.rotatingClauseDeletion:
        return ClozeOcclusion.rotatingClauseDeletion(
          passage: widget.state.currentPassage,
          clauseIndex: _acquisitionState.currentClauseIndex,
        );

      case AcquisitionLevel.firstTwoWordsScaffolding:
        return ClozeOcclusion.firstTwoWordsScaffolding(
          passage: widget.state.currentPassage,
        );
    }
  }

  void _handleCompletion() {
    // User successfully completed current round
    final nextState = _acquisitionState.advance();

    if (nextState == null) {
      // All rounds completed! Advance to next practice mode
      widget.onContinue();
    } else {
      // Move to next round
      setState(() {
        _acquisitionState = nextState;
        _occlusion = _createOcclusionForCurrentRound();
      });
    }
  }

  void _handleFailure() {
    // User failed current round, step back to easier round
    final previousState = _acquisitionState.stepBack();

    if (previousState != null) {
      setState(() {
        _acquisitionState = previousState;
        _occlusion = _createOcclusionForCurrentRound();
      });
    }
  }
}
```

### 2. Update Practice State Model

Optionally extend `PracticeState` to track acquisition progress:

```dart
class PracticeState {
  // ... existing fields
  final AcquisitionState? acquisitionState;

  // Add to copyWith method
  AcquisitionState? acquisitionState;
}
```

### 3. Persistence (Optional)

To persist acquisition progress across sessions, add to `UserProgress` table:

```dart
// In lib/data/database/tables.dart
@DataClassName('UserProgress')
class UserProgressTable extends Table {
  // ... existing columns

  /// Current acquisition level within Scaffolding Mode (0-2)
  IntColumn get acquisitionLevel => integer().withDefault(const Constant(0))();

  /// For Round 2: current clause index being tested
  IntColumn get currentClauseIndex => integer().withDefault(const Constant(0))();
}
```

## Testing

All new models have comprehensive unit tests:

- `test/models/clause_segmentation_test.dart`
- `test/models/cloze_occlusion_test.dart`
- `test/models/acquisition_state_test.dart`

Run tests with:
```bash
flutter test test/models/clause_segmentation_test.dart
flutter test test/models/cloze_occlusion_test.dart
flutter test test/models/acquisition_state_test.dart
```

## UI Considerations

### Round Indicator

Consider adding a round indicator to help users understand their progress:

```dart
Text(
  'Round ${_acquisitionState.currentLevel.level + 1}/3: ${_acquisitionState.currentLevel.displayName}',
  style: RedLetterTypography.caption,
)
```

### Failure UI

When stepping back due to failure, consider showing a brief message:

```dart
if (failed) {
  SnackBar(
    content: Text('Let\'s try an easier round first'),
    duration: Duration(seconds: 2),
  )
}
```

### Clause Rotation Progress (Round 2)

For Round 2, show clause rotation progress:

```dart
if (_acquisitionState.currentLevel == AcquisitionLevel.rotatingClauseDeletion) {
  Text(
    'Clause ${_acquisitionState.currentClauseIndex + 1}/${_acquisitionState.totalClauses}',
    style: RedLetterTypography.caption,
  )
}
```

## Performance Notes

- **Clause segmentation** is deterministic and can be cached
- **Content word filtering** uses a simple set lookup (O(1))
- **Random word selection** is seeded for reproducibility in testing
- All operations complete within the 8-16ms frame budget requirement

## Migration Path

1. **Phase 1**: Add new models alongside existing `WordOcclusion` (done)
2. **Phase 2**: Update `ScaffoldingScreen` to use `ClozeOcclusion`
3. **Phase 3**: Add persistence to track acquisition state
4. **Phase 4**: Add UI indicators for round progression
5. **Phase 5**: Remove deprecated `WordOcclusion` (if no longer needed for other modes)

## Related Issues

- ✅ `rl-mkk` - Clause Segmentation logic
- ✅ `rl-1yq` - Cloze Round 1: Random word removal
- ✅ `rl-6y5` - Cloze Round 2: Rotating clause deletion
- ✅ `rl-7bq` - Cloze Round 3: First-2-words scaffolding
- ✅ `rl-gfq` - Refine Impression Mode with read aloud
- ✅ `rl-ofe` - Acquisition Failure/Retry State Machine

## Questions?

This implementation follows the architecture principles in `CLAUDE.md`:
- Client-side logic (no backend dependencies)
- Offline-first (all state managed locally)
- Performance-conscious (frame budget compliant)
- Type-safe (leveraging Dart's type system)
