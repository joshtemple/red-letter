# Flows

## Learning Flow

Each of these is a **step** in a **flow**, the **Learning** flow.

1. **Impression screen**: Tap to reveal each clause, eventually enable read-aloud
2. **Reflection screen**: What does this passage mean to you?
  - For now, disable this step but keep it around
3. **Scaffolding screen**: Progressively delete more and more of the passage (a few words, start of clauses, rotating clause, full passage)
  - Failed words are prioritized for testing in later rounds (perhaps round n + 2 to interleave?)
  - Tap anywhere on the screen to reveal a word if you don't know it, but still have to type it
  - User has two "lives" allowing them to make two mistakes before failing the stage
  - Failure regresses by one level, success advances one level until complete
    - Failure in first round stays on the first round
  - Smart logic for typo detection
  - Last round does not display the underlines

We are going to delete Prompted Mode and Reconstruction Mode (their associated logic and screens), they are redundant in the current design.

## Review Flow

Review flow is the same as Learning Flow, except it starts at the final step of the Scaffolding screen where the user is expected to fully input the passage. Failing it does not regress to a prior stage, but sends it back to the scheduler (FSRS) with an "Again" rating.

