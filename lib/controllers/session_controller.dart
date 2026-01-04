import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value; // Added for copyWith
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';
import 'package:red_letter/services/working_set_service.dart';
import 'package:fsrs/fsrs.dart' show Rating;
import 'package:red_letter/models/practice_mode.dart'; // Added for handleStepCompletion

/// Controller that manages the daily review session lifecycle.
///
/// Handles loading the review queue, tracking progress through cards,
/// submitting reviews, and updating FSRS scheduling.
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

  /// Handle a failed review (regression) for the current card.
  ///
  /// Submits an 'Again' rating to FSRS but keeps the card as the current card,
  /// effectively queueing it for immediate relearning (Acquisition flow).
  Future<void> handleRegression(SessionMetrics metrics) async {
    if (currentCard == null) {
      throw StateError('No current card to regress');
    }

    final currentCardData = currentCard!;
    // Force 'Again' rating for regression
    const rating = Rating.again;

    // Update FSRS scheduling
    final updatedProgressCompanion = _fsrsService.reviewPassage(
      passageId: currentCardData.passageId,
      progress: currentCardData,
      rating: rating,
    );

    // Save to database
    await _progressDAO.upsertProgress(updatedProgressCompanion);

    // Fetch updated record from DB to get clean UserProgress object
    // This allows us to have the actual UserProgress model instead of the Companion
    final refreshedProgress = await _progressDAO.getProgressByPassageId(
      currentCardData.passageId,
    );

    if (refreshedProgress != null) {
      // Update the in-memory card to reflect new state
      _cards[_currentIndex] = refreshedProgress;
    }

    // Record metrics but do NOT advance index
    _completedReviews.add(metrics);

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

  /// Handles completion of a practice step (Impression, Reflection, etc.).
  ///
  /// Called by the UI after each step is successfully completed.
  /// Persists step-specific data (e.g., reflection text) and intermediate mastery levels.
  Future<void> handleStepCompletion({
    required String passageId,
    required PracticeMode mode,
    required SessionMetrics metrics,
  }) async {
    try {
      switch (mode) {
        case PracticeMode.impression:
          // No specific persistence needed yet.
          // Could update 'lastSeen' timestamp if we had one for non-FSRS.
          break;

        case PracticeMode.reflection:
          // Save valid reflection text + set partial mastery
          if (metrics.userInput.isNotEmpty) {
            await _progressDAO.updateSemanticReflection(
              passageId,
              metrics.userInput,
            );
            await _progressDAO.updateMasteryLevel(
              passageId,
              1,
            ); // Reflection done

            // Update in-memory card
            _updateInMemoryCard(
              passageId,
              (p) => p.copyWith(
                semanticReflection: Value(metrics.userInput),
                masteryLevel: 1,
              ),
            );
          }
          break;

        case PracticeMode.randomWords:
          // Completed Round 1 -> Mastery 2
          await _progressDAO.updateMasteryLevel(passageId, 2);
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 2));
          break;

        case PracticeMode.rotatingClauses:
          // Completed Round 2 -> Mastery 3
          await _progressDAO.updateMasteryLevel(passageId, 3);
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 3));
          break;

        case PracticeMode.firstTwoWords:
          // Completed Round 3 -> Mastery 4
          await _progressDAO.updateMasteryLevel(passageId, 4);
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 4));
          break;

        case PracticeMode.prompted:
          // Completed Prompted -> Mastery 5
          await _progressDAO.updateMasteryLevel(passageId, 5);
          _updateInMemoryCard(passageId, (p) => p.copyWith(masteryLevel: 5));
          break;

        case PracticeMode.reconstruction:
          // Reconstruction marks the end of the card.
          // Persistence is handled by the explicit submitReview call in the UI
          // to manage FSRS scheduling accurately.
          break;
      }
    } catch (e) {
      debugPrint('Error persisting step: $e');
      // Non-fatal, don't crash session
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
