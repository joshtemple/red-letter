import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value; // Added for copyWith
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';
import 'package:red_letter/services/working_set_service.dart';
import 'package:fsrs/fsrs.dart' show Rating;
import 'package:red_letter/models/practice_step.dart'; // Added for handleStepCompletion

/// Controller that manages the daily practice session lifecycle.
///
/// Hierarchy: Session → Flow → Steps → Scaffolding → Levels → Rounds → Lives
///
/// Handles loading the review queue, tracking progress through cards,
/// submitting reviews, and updating FSRS scheduling.
///
/// This controller manages the "Session" level of the hierarchy, orchestrating
/// the individual "Flows" (Learning vs Review) and their internal "Steps".
class SessionController extends ChangeNotifier {
  final UserProgressDAO _progressDAO;
  final WorkingSetService _workingSetService;
  final FSRSSchedulerService _fsrsService;

  // New: Track current active card's ephemeral state if needed, or just rely on DB write.

  /// Cards in this review session (mix of review, relearning, and new cards)
  List<UserProgress> _cards = [];

  /// Current card index (0-based)
  int _currentIndex = 0;

  /// Completed reviews with performance metrics
  final List<SessionMetrics> _completedReviews = [];

  /// Whether the session has been loaded
  bool _isLoaded = false;

  SessionController({
    required UserProgressDAO progressDAO,
    required WorkingSetService workingSetService,
    required FSRSSchedulerService fsrsService,
  }) : _progressDAO = progressDAO,
       _workingSetService = workingSetService,
       _fsrsService = fsrsService;

  // ========== Getters ==========

  /// Get all cards in the session
  List<UserProgress> get cards => List.unmodifiable(_cards);

  /// Get current card index
  int get currentIndex => _currentIndex;

  /// Get completed reviews
  List<SessionMetrics> get completedReviews =>
      List.unmodifiable(_completedReviews);

  /// Whether the session has been loaded
  bool get isLoaded => _isLoaded;

  /// Whether all cards have been reviewed
  bool get isComplete => _currentIndex >= _cards.length && _cards.isNotEmpty;

  /// Get the current card, or null if none available
  UserProgress? get currentCard =>
      _currentIndex < _cards.length ? _cards[_currentIndex] : null;

  /// Get remaining cards count
  int get remainingCount => _cards.length - _currentIndex;

  /// Get total cards in session
  int get totalCount => _cards.length;

  /// Get session progress as percentage (0-100)
  double get progressPercent =>
      _cards.isEmpty ? 100.0 : (_currentIndex / _cards.length) * 100;

  // ========== Session Management ==========

  /// Load a new review session.
  ///
  /// Loads due cards (relearning + review + learning) and new cards (within budget).
  /// Priority: relearning > review > learning > new.
  Future<void> loadSession({int? reviewLimit, int? newCardLimit}) async {
    // Get review queue (due cards, prioritized by urgency)
    final reviewQueue = await _progressDAO.getReviewQueue(limit: reviewLimit);

    // Get new cards within working set budget
    final newCards = await _workingSetService.getAvailableNewCards(
      overrideLimit: newCardLimit,
    );

    // Combine: reviews first, then new cards
    _cards = [...reviewQueue, ...newCards];

    // Ensure all new cards have a database entry (ID != -1)
    // This prevents issues where we try to update a card that doesn't exist yet.
    for (var i = 0; i < _cards.length; i++) {
      if (_cards[i].id == -1) {
        // Create initial progress in DB
        final newId = await _progressDAO.createProgress(_cards[i].passageId);
        // Update in-memory card with real ID
        _cards[i] = _cards[i].copyWith(id: newId);
      }
    }

    _currentIndex = 0;
    _completedReviews.clear();
    _isLoaded = true;

    notifyListeners();
  }

  /// Submit a review for the current card and advance.
  ///
  /// Updates the card's FSRS scheduling data and moves to the next card.
  Future<void> submitReview(SessionMetrics metrics) async {
    if (currentCard == null) {
      throw StateError('No current card to review');
    }

    final currentCardData = currentCard!;
    final rating = metrics.toFSRSRating();

    // Update FSRS scheduling
    final updatedProgress = _fsrsService.reviewPassage(
      passageId: currentCardData.passageId,
      progress: currentCardData,
      rating: rating,
    );

    // Save to database
    await _progressDAO.upsertProgress(updatedProgress);

    // Update state: record metrics and advance
    _completedReviews.add(metrics);
    _currentIndex++;

    notifyListeners();
  }

  /// Skip the current card without reviewing.
  ///
  /// Moves to the next card but doesn't update scheduling.
  void skipCard() {
    if (currentCard != null) {
      _currentIndex++;
      notifyListeners();
    }
  }

  /// Go back to the previous card (if possible).
  void previousCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// Reset the session to initial state.
  void resetSession() {
    _cards = [];
    _currentIndex = 0;
    _completedReviews.clear();
    _isLoaded = false;
    notifyListeners();
  }

  // ========== Step Persistence ==========

  /// Handles completion of a passage (L4) or a failure in Review Flow.
  ///
  /// Centralizes logic for both Learning and Review flows.
  Future<void> handlePassageCompletion(SessionMetrics metrics) async {
    if (currentCard == null) return;

    final card = currentCard!;
    final isReview = card.state == 1; // 1 = Review
    final rating = metrics.toFSRSRating();

    // Logic:
    // Review Flow:
    // - Always submit to FSRS (Success or Fail).
    // - Advance to next card (Reschedule).
    // Learning Flow:
    // - Only called on Success (Completion of L4).
    // - Failures are handled internally by PracticeController (Regression).
    // - Submit Rating.good (Graduation) to FSRS.
    // - Advance.

    if (isReview) {
      // Review Flow
      // Submit actual rating (Again/Hard/Good/Easy)
      await _submitReviewInternal(rating, metrics);
    } else {
      // Learning Flow (Success)
      // Force 'Good' rating for graduation
      await _submitReviewInternal(Rating.good, metrics);
    }
  }

  /// Internal method to submit review to FSRS and advance.
  Future<void> _submitReviewInternal(
    Rating rating,
    SessionMetrics metrics,
  ) async {
    if (currentCard == null) return;

    final currentCardData = currentCard!;

    // Update FSRS scheduling
    final updatedProgress = _fsrsService.reviewPassage(
      passageId: currentCardData.passageId,
      progress: currentCardData,
      rating: rating,
    );

    // Save to database
    await _progressDAO.upsertProgress(updatedProgress);

    // Update state: record metrics and advance
    _completedReviews.add(metrics);
    _currentIndex++;

    notifyListeners();
  }

  /// Deprecated: Use handlePassageCompletion instead.
  /// Handles completion of a practice step (Impression, Reflection, etc.).
  ///
  /// Called by the UI after each step is successfully completed.
  /// Persists step-specific data (e.g., reflection text) and intermediate mastery levels.
  Future<void> handleStepCompletion({
    required String passageId,
    required PracticeStep mode,
    required SessionMetrics metrics,
  }) async {
    try {
      // NOTE: We no longer persist intermediate states to the database.
      // Persistence only happens on successful completion of the full loop (submitReview).
      // We only update the in-memory card to drive the UI state (resume within session).

      switch (mode) {
        case PracticeStep.impression:
          // Nothing to do
          break;

        case PracticeStep.reflection:
          // Update in-memory: Save content + set mastery 1
          if (metrics.userInput.isNotEmpty) {
            _updateInMemoryCard(
              passageId,
              (p) => p.copyWith(
                semanticReflection: Value(metrics.userInput),
                masteryLevel: 1,
              ),
            );
          }
          break;

        case PracticeStep.randomWords:
          // Update in-memory: Mastery 2 (Scaffolding L1)
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 2));
          break;

        case PracticeStep.firstTwoWords:
          // Update in-memory: Mastery 3 (Scaffolding L2)
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 3));
          break;

        case PracticeStep.rotatingClauses:
          // Update in-memory: Mastery 4 (Scaffolding L3)
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 4));
          break;

        case PracticeStep.fullPassage:
          // Full passage marks card completion (Scaffolding L4).
          // Handled by handlePassageCompletion.
          break;
      }
    } catch (e) {
      debugPrint('Error handling step completion: $e');
      // Non-fatal
    }
  }

  void _updateInMemoryCard(
    String passageId,
    UserProgress Function(UserProgress) updateFn,
  ) {
    final index = _cards.indexWhere((c) => c.passageId == passageId);
    if (index != -1) {
      _cards[index] = updateFn(_cards[index]);
      notifyListeners();
    }
  }

  // ========== Statistics ==========

  /// Get session statistics.
  Map<String, dynamic> getSessionStats() {
    if (_completedReviews.isEmpty) {
      return {
        'cardsReviewed': 0,
        'averageAccuracy': 0.0,
        'averageWPM': 0.0,
        'averageRecallQuality': 0.0,
      };
    }

    final totalAccuracy = _completedReviews
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b);
    final totalWPM = _completedReviews
        .map((m) => m.wpm)
        .reduce((a, b) => a + b);
    final totalRecall = _completedReviews
        .map((m) => m.recallQuality)
        .reduce((a, b) => a + b);

    final count = _completedReviews.length;

    return {
      'cardsReviewed': count,
      'averageAccuracy': totalAccuracy / count,
      'averageWPM': totalWPM / count,
      'averageRecallQuality': totalRecall / count,
    };
  }
}
