import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';

/// Manages the "Working Set" - limits on new cards introduced per day.
///
/// This prevents overwhelming the user with too many new passages at once
/// and ensures a sustainable learning pace compatible with FSRS scheduling.
class WorkingSetService {
  final UserProgressDAO _progressDAO;

  /// Default maximum number of new cards to introduce per day
  static const int defaultNewCardsPerDay = 5;

  /// Current configured limit for new cards per day
  final int newCardsPerDay;

  WorkingSetService(
    this._progressDAO, {
    this.newCardsPerDay = defaultNewCardsPerDay,
  });

  /// Get available new cards within the daily budget.
  ///
  /// Returns new cards (never reviewed) up to the configured daily limit.
  /// If [overrideLimit] is provided, uses that instead of the configured limit.
  Future<List<UserProgress>> getAvailableNewCards({int? overrideLimit}) {
    final limit = overrideLimit ?? newCardsPerDay;
    return _progressDAO.getNewCards(limit: limit);
  }

  /// Check if more new cards can be introduced today.
  ///
  /// This is a simple implementation that just checks if there are any
  /// new cards available within the budget. A more sophisticated version
  /// could track cards introduced per calendar day.
  Future<bool> canIntroduceMoreNewCards() async {
    final newCards = await _progressDAO.getNewCards(limit: 1);
    return newCards.isNotEmpty;
  }

  /// Get the number of new cards that can still be introduced.
  ///
  /// This is a simple implementation that returns the full budget.
  /// A more sophisticated version would track how many cards were
  /// introduced today and return the remaining budget.
  ///
  /// Future enhancement: Track per-day introduction in a separate table
  /// or using lastReviewed timestamps to count today's new cards.
  Future<int> getRemainingNewCardBudget() async {
    // TODO: Implement daily tracking of introduced cards
    // For now, just return the full budget
    return newCardsPerDay;
  }

  /// Get total count of new cards (not yet in review/relearning state).
  ///
  /// Useful for UI to show "X new cards available".
  Future<int> getTotalNewCardsCount() async {
    final newCards = await _progressDAO.getNewCards();
    return newCards.length;
  }
}
