/// The type of flow for a practice session.
enum FlowType {
  /// The standard acquisition flow (Impression -> Scaffolding L1-L4).
  /// Used for new cards or cards being relearned.
  learning,

  /// The review flow (Scaffolding L4 only).
  /// Used for cards that are due for review.
  review,
}
