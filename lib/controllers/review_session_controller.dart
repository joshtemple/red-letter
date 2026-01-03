import 'package:flutter/foundation.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';
import 'package:red_letter/services/working_set_service.dart';

/// Controller that manages the daily review session lifecycle.
///
/// Handles loading the review queue, tracking progress through cards,
/// submitting reviews, and updating FSRS scheduling.
class ReviewSessionController extends ChangeNotifier {
  final UserProgressDAO _progressDAO;
  final WorkingSetService _workingSetService;
  final FSRSSchedulerService _fsrsService;

  /// Cards in this review session (mix of review, relearning, and new cards)
  List<UserProgress> _cards = [];

  /// Current card index (0-based)
  int _currentIndex = 0;

  /// Completed reviews with performance metrics
  final List<SessionMetrics> _completedReviews = [];

  /// Whether the session has been loaded
  bool _isLoaded = false;

  ReviewSessionController({
    required UserProgressDAO progressDAO,
    required WorkingSetService workingSetService,
    required FSRSSchedulerService fsrsService,
  })  : _progressDAO = progressDAO,
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
  Future<void> loadSession({
    int? reviewLimit,
    int? newCardLimit,
  }) async {
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

    final totalAccuracy =
        _completedReviews.map((m) => m.accuracy).reduce((a, b) => a + b);
    final totalWPM =
        _completedReviews.map((m) => m.wpm).reduce((a, b) => a + b);
    final totalRecall =
        _completedReviews.map((m) => m.recallQuality).reduce((a, b) => a + b);

    final count = _completedReviews.length;

    return {
      'cardsReviewed': count,
      'averageAccuracy': totalAccuracy / count,
      'averageWPM': totalWPM / count,
      'averageRecallQuality': totalRecall / count,
    };
  }
}
