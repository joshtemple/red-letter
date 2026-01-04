import 'package:flutter/material.dart';
import 'package:red_letter/controllers/session_controller.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/screens/practice_session_view.dart';
import 'package:red_letter/services/fsrs_scheduler_service.dart';
import 'package:red_letter/services/working_set_service.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:fsrs/fsrs.dart' show Rating;

class SessionScreen extends StatefulWidget {
  final PassageRepository repository;

  const SessionScreen({super.key, required this.repository});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  SessionController? _controller;
  bool _isLoading = true;
  String? _error;

  // Track current passage text and mode manually since Controller only has UserProgress
  Passage? _currentPassage;
  PracticeMode?
  _forcedMode; // Used for handling regression (overriding default)

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final fsrsService = FSRSSchedulerService();
      final workingSetService = WorkingSetService(
        widget.repository.progressDAO,
      );

      _controller = SessionController(
        progressDAO: widget.repository.progressDAO,
        workingSetService: workingSetService,
        fsrsService: fsrsService,
      );

      // Listen to card changes to load the passage text
      _controller!.addListener(_onCardChanged);

      // Load the session (e.g. 10 review, 5 new)
      // TODO: Make these limits configurable/dynamic
      await _controller!.loadSession(reviewLimit: 20, newCardLimit: 5);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Load first card if available
        _onCardChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onCardChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onCardChanged() async {
    if (_controller == null || _controller!.currentCard == null) {
      if (mounted) {
        setState(() {
          _currentPassage = null;
          _forcedMode = null;
        });
      }
      return;
    }

    final card = _controller!.currentCard!;

    // Reset forced mode when changing cards
    if (mounted) {
      setState(() {
        _forcedMode = null;
      });
    }

    // Fetch passage text
    final pwp = await widget.repository.getPassageWithProgress(card.passageId);

    if (mounted && pwp != null) {
      setState(() {
        _currentPassage = Passage.fromText(
          id: pwp.passageId,
          text: pwp.passage.passageText,
          reference: pwp.passage.reference,
        );
      });
    }
  }

  void _handleStepComplete(SessionMetrics metrics) async {
    if (_controller == null) return;

    final card = _controller!.currentCard!;
    final isReview = card.state == 1; // 1 = Review
    final rating = metrics.toFSRSRating();

    // Logic:
    // If in Review Mode (Reconstruction used for review) AND Rating is Again -> Regress
    // Else -> Submit and Advance

    if (isReview && rating == Rating.again) {
      // REGRESSION FLOW
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missed it. Let\'s practice.')),
      );

      // 1. Submit "Again" to FSRS but keep card
      await _controller!.handleRegression(metrics);

      // 2. Switch UI to Scaffolding (Acquisition flow)
      if (mounted) {
        setState(() {
          _forcedMode = PracticeMode.randomWords;
        });
      }
    } else {
      // STANDARD FLOW
      await _controller!.submitReview(metrics);
      // _onCardChanged will be triggered by listener if index/card changes
      // But actually listener usage in _onCardChanged might be tricky if notifyListeners happens inside submitReview
      // It should work.
    }
  }

  void _handleIntermediateStep(PracticeMode mode, String? input) {
    if (_controller == null || _currentPassage == null) return;

    // Create intermediate metrics (approximate duration)
    // We don't have exact duration delta here easily without controller tracking it per step.
    // For now we just pass input.
    final metrics = SessionMetrics(
      passageText: _currentPassage!.text,
      userInput: input ?? '',
      durationMs: 0, // Placeholder
      levenshteinDistance: 0, // Placeholder
    );

    _controller!.handleStepCompletion(
      passageId: _currentPassage!.id,
      mode: mode,
      metrics: metrics,
    );
  }

  PracticeMode _getInitialMode() {
    if (_forcedMode != null) return _forcedMode!;

    if (_controller?.currentCard == null) return PracticeMode.impression;

    final card = _controller!.currentCard!;

    // State 0 = Learning (Acquisition)
    // State 1 = Review
    // State 2 = Relearning

    if (card.state == 1) {
      // Review -> Reconstruction
      return PracticeMode.reconstruction;
    }

    // Acquisition (New=0) or Relearning (Again=2)
    // Resume based on mastery level
    switch (card.masteryLevel) {
      case 0:
        return PracticeMode.impression;
      case 1:
        return PracticeMode.randomWords; // Resume after Reflection
      case 2:
        return PracticeMode.rotatingClauses; // Resume after Random Words
      case 3:
        return PracticeMode.firstTwoWords; // Resume after Rotating Clauses
      case 4:
        return PracticeMode.prompted; // Resume after First Two Words
      default:
        return PracticeMode.impression;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: RedLetterColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: RedLetterColors.background,
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Session Complete
    if (_controller!.isComplete || _controller!.cards.isEmpty) {
      return _SessionSummaryView(controller: _controller!);
    }

    // Loading next card
    if (_currentPassage == null) {
      return const Scaffold(
        backgroundColor: RedLetterColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Active Practice
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: RedLetterColors.secondaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_controller!.currentIndex + 1} / ${_controller!.totalCount}',
          style: const TextStyle(
            color: RedLetterColors.secondaryText,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
      ),
      body: PracticeSessionView(
        // Use key to force rebuild when mode or passage changes
        key: ValueKey('${_currentPassage!.id}_${_getInitialMode()}'),
        repository: widget.repository,
        initialPassage: _currentPassage!,
        initialMode: _getInitialMode(),
        onComplete: _handleStepComplete,
        onStepComplete: _handleIntermediateStep,
      ),
    );
  }
}

class _SessionSummaryView extends StatelessWidget {
  final SessionController controller;

  const _SessionSummaryView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = controller.getSessionStats();

    return Scaffold(
      backgroundColor: RedLetterColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: RedLetterColors.accent,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Session Complete',
                style: TextStyle(
                  color: RedLetterColors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              _buildStatRow('Cards Reviewed', '${stats['cardsReviewed']}'),
              const SizedBox(height: 16),
              _buildStatRow(
                'Accuracy',
                '${(stats['averageAccuracy'] * 100).toStringAsFixed(1)}%',
              ),

              const SizedBox(height: 64),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RedLetterColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('FINISH'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RedLetterColors.secondaryText,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: RedLetterColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
