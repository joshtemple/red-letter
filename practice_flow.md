# Practice Flows

## Terminology Hierarchy
**Session** → **Flow** → **Step** → **Scaffolding Level** → **Round** → **Lives**

## Learning Flow

Designed for acquiring new passages. Consists of sequential **Steps**:

1. **Impression Step**: Full text display with visual mnemonic.
2. **Reflection Step**: Semantic engagement prompt ("What does this mean to you?").
3. **Scaffolding Step**: Progressive occlusion ladder with 4 **Levels**:
   - **Level 1 (RandomWords)**: 1-2 words removed per clause. (Fixed 3 Rounds)
   - **Level 2 (FirstTwoWords)**: Only first 2 words of each clause visible. (1 Round)
   - **Level 3 (RotatingClauses)**: One clause hidden at a time. (N Rounds = clause count)
   - **Level 4 (FullPassage)**: 100% hidden, no underlines. (1 Round)

### Mechanics
- **Lives**: 2 lives per **Round**. Reset at the start of each round.
- **Progression**: completing a round advances to the next round/level.
- **Regression**: losing all lives regresses to the previous **Level** (L1 stays at L1).
- **Assistance**: Tapping a hidden word reveals it (costs 1 life).

## Review Flow

Designed for maintaining existing passages via FSRS scheduling.

- **Entry Point**: Starts directly at **Scaffolding Level 4 (FullPassage)**.
- **Success**: Completing the round submits a "Good" or "Easy" rating to FSRS.
- **Failure**: Failing the round triggers a regression into the **Learning Flow** (starting at L1) and submits an "Again" rating to FSRS.
