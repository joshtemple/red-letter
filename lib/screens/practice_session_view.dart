import 'package:flutter/material.dart';
import 'package:red_letter/data/models/session_metrics.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/impression_screen.dart';
import 'package:red_letter/screens/reflection_screen.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';
import 'package:red_letter/screens/prompted_screen.dart';
import 'package:red_letter/screens/reconstruction_screen.dart';
import 'package:red_letter/controllers/practice_controller.dart';
import 'package:red_letter/utils/levenshtein.dart';

class PracticeSessionView extends StatefulWidget {
  final PassageRepository repository;
  final Passage initialPassage;
  final PracticeMode initialMode;
  final Function(SessionMetrics) onComplete;
  final Function(PracticeMode, String?)? onStepComplete; // New callback
  final ValueChanged<int>? onLivesChange;

  const PracticeSessionView({
    super.key,
    required this.repository,
    required this.initialPassage,
    required this.initialMode,
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
    } else if (oldWidget.initialMode != widget.initialMode) {
      // Only reload if the new mode is strictly different from our CURRENT state
      // This prevents resetting the controller when the parent catches up to our internal state
      if (_controller != null &&
          _controller!.value.currentMode != widget.initialMode) {
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
            initialMode: widget.initialMode,
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

    // Check strict match for Prompted/Reconstruction
    bool success = true;
    if (currentState.currentMode == PracticeMode.reconstruction) {
      if (input == null ||
          !PassageValidator.isStrictMatch(widget.initialPassage.text, input)) {
        success = false;
      }
    }

    if (success) {
      // If we are about to finish Reconstruction
      if (currentState.currentMode == PracticeMode.reconstruction) {
        _submitMetrics(input);
      } else {
        _controller!.advance(input);
      }
    } else {
      // Failure -> Regress
      _controller!.regress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect. Stepping back...'),
          duration: Duration(seconds: 1),
        ),
      );
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

        switch (state.currentMode) {
          case PracticeMode.impression:
            currentScreen = ImpressionScreen(
              state: state,
              onContinue: () => _handleStep(),
            );
            break;
          case PracticeMode.reflection:
            currentScreen = ReflectionScreen(
              state: state,
              onContinue: (text) => _handleStep(text),
            );
            break;
          case PracticeMode.randomWords:
          case PracticeMode.rotatingClauses:
          case PracticeMode.firstTwoWords:
            currentScreen = ScaffoldingScreen(
              key: ValueKey('cloze_${state.currentMode.name}'),
              state: state,
              onContinue: () => _handleStep(),
              onLivesChange: widget.onLivesChange,
            );
            break;
          case PracticeMode.prompted:
            currentScreen = PromptedScreen(
              state: state,
              onContinue: (input) => _handleStep(input),
            );
            break;
          case PracticeMode.reconstruction:
            currentScreen = ReconstructionScreen(
              state: state,
              onContinue: (input) => _handleStep(input),
            );
            break;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: KeyedSubtree(
            key: ValueKey(state.currentMode),
            child: currentScreen,
          ),
        );
      },
    );
  }
}
