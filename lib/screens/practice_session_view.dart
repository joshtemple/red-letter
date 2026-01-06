import 'package:flutter/material.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/models/practice_step.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/impression_screen.dart';
import 'package:red_letter/screens/reflection_screen.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';
import 'package:red_letter/controllers/practice_controller.dart';
import 'package:red_letter/utils/levenshtein.dart';

class PracticeSessionView extends StatefulWidget {
  final PassageRepository repository;
  final Passage initialPassage;
  final PracticeStep initialStep;
  final Function(SessionMetrics) onComplete;
  final Function(PracticeStep, String?)? onStepComplete; // New callback
  final ValueChanged<int>? onLivesChange;

  const PracticeSessionView({
    super.key,
    required this.repository,
    required this.initialPassage,
    required this.initialStep,
    required this.onComplete,
    this.onStepComplete, // Optional
    this.onLivesChange,
  });

  @override
  State<PracticeSessionView> createState() => _PracticeSessionViewState();
}

class _PracticeSessionViewState extends State<PracticeSessionView> {
  PracticeController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPassage();
  }

  // Reloads if the passage changes (e.g. parent widget changes the passage)
  @override
  void didUpdateWidget(PracticeSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPassage.id != widget.initialPassage.id) {
      _loadPassage();
    } else if (oldWidget.initialStep != widget.initialStep) {
      // Only reload if the new mode is strictly different from our CURRENT state
      // This prevents resetting the controller when the parent catches up to our internal state
      if (_controller != null &&
          _controller!.value.currentStep != widget.initialStep) {
        _loadPassage();
      }
    }
  }

  Future<void> _loadPassage() async {
    try {
      if (mounted) {
        setState(() {
          _controller = PracticeController(
            widget.initialPassage,
            initialStep: widget.initialStep,
            onStepComplete: widget.onStepComplete,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading passage: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleStep([String? input]) {
    if (_controller == null) return;

    final currentState = _controller!.value;

    // Check if we're finishing the session (fullPassage is the final step)
    if (currentState.currentStep == PracticeStep.fullPassage &&
        currentState.isComplete) {
      _submitMetrics(input);
    } else {
      _controller!.advance(input);
    }
  }

  void _submitMetrics(String? input) {
    if (_controller == null) return;

    // We grab duration from the *current* state before any transition
    // But actually, we want the total time spent up to this point?
    // The controller tracks elapsedTime.

    final finalInput = input ?? '';
    final duration = _controller!.value.elapsedTime.inMilliseconds;

    final metrics = SessionMetrics(
      passageText: widget.initialPassage.text,
      userInput: finalInput,
      durationMs: duration,
      levenshteinDistance: levenshtein(widget.initialPassage.text, finalInput),
    );

    widget.onComplete(metrics);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<PracticeState>(
      valueListenable: _controller!,
      builder: (context, state, child) {
        Widget currentScreen;

        switch (state.currentStep) {
          case PracticeStep.impression:
            currentScreen = ImpressionScreen(
              state: state,
              onContinue: () => _handleStep(),
            );
            break;
          case PracticeStep.reflection:
            currentScreen = ReflectionScreen(
              state: state,
              onContinue: (text) => _handleStep(text),
            );
            break;
          case PracticeStep.randomWords:
          case PracticeStep.firstTwoWords:
          case PracticeStep.rotatingClauses:
          case PracticeStep.fullPassage:
            currentScreen = ScaffoldingScreen(
              key: ValueKey('cloze_${state.currentStep.name}'),
              state: state,
              onContinue: () => _handleStep(),
              onLivesChange: widget.onLivesChange,
              onRegress: () => _controller?.regress(),
            );
            break;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: KeyedSubtree(
            key: ValueKey(state.currentStep),
            child: currentScreen,
          ),
        );
      },
    );
  }
}
