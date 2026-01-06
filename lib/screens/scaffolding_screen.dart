import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_letter/mixins/typing_practice_mixin.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/practice_step.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

import 'package:red_letter/widgets/inline_passage_view.dart';
import 'package:red_letter/models/passage_validator.dart';

/// Screen responsible for the Scaffolding Step of the practice flow.
///
/// Hierarchy: ... → Scaffolding (Step) → Level (L1-L4) → Round → Lives
///
/// Renders the current Scaffolding Level (e.g. RandomWords, FirstTwoWords)
/// and handles the Round-based progression logic (Lives, Success/Failure).
class ScaffoldingScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final ClozeOcclusion? occlusion;
  final ValueChanged<int>? onLivesChange;
  final Function(String input, int durationMs)? onRegress;

  const ScaffoldingScreen({
    super.key,
    required this.state,
    required this.onContinue,
    this.occlusion,
    this.onLivesChange,
    this.onRegress,
  });

  @override
  State<ScaffoldingScreen> createState() => _ScaffoldingScreenState();
}

class _ScaffoldingScreenState extends State<ScaffoldingScreen>
    with TickerProviderStateMixin, TypingPracticeMixin {
  late ClozeOcclusion _occlusion;
  late Set<int> _originallyHiddenIndices;
  Set<int> _revealedIndices = {}; // Track manually revealed words
  int _lives = 2;
  bool _isSuccessProcessing = false;

  @override
  void initState() {
    super.initState();
    _lives = widget.state.livesRemaining; // Initialize from state
    _occlusion = widget.occlusion ?? _generateOcclusionForStep();
    _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);

    // Report initial lives to parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLivesChange?.call(_lives);
      focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(ScaffoldingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.currentStep != oldWidget.state.currentStep ||
        widget.state.currentRound != oldWidget.state.currentRound ||
        widget.state.currentPassage.id != oldWidget.state.currentPassage.id ||
        (widget.state.livesRemaining == 2 && _lives < 2)) {
      // Reset for new round/step/passage or regression (lives reset to 2)
      setState(() {
        _lives = widget.state.livesRemaining;
        _occlusion = widget.occlusion ?? _generateOcclusionForStep();
        _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);
        _revealedIndices = {};
        isProcessingError = false;
        _isSuccessProcessing = false;
        inputController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLivesChange?.call(_lives);
        focusNode.requestFocus();
      });
    }
  }

  // ... (omitted methods _generateOcclusionForStep, _isComplete, _onInputChange same as before)

  ClozeOcclusion _generateOcclusionForStep() {
    final passage = widget.state.currentPassage;
    switch (widget.state.currentStep) {
      case PracticeStep.randomWords:
        return ClozeOcclusion.randomWordPerClause(
          passage: passage,
          // Use round as seed variant to ensure different patterns across rounds
          seed: passage.hashCode + widget.state.currentRound,
        );
      case PracticeStep.rotatingClauses:
        return ClozeOcclusion.rotatingClauseDeletion(
          passage: passage,
          // L3: Round index maps directly to clause index
          clauseIndex: widget.state.currentRound,
        );
      case PracticeStep.firstTwoWords:
        return ClozeOcclusion.firstTwoWordsScaffolding(passage: passage);
      case PracticeStep.fullPassage:
        return ClozeOcclusion.fullPassage(passage: passage);
      default:
        return ClozeOcclusion.randomWordPerClause(passage: passage);
    }
  }

  void _onInputChange(String input) {
    if (_isSuccessProcessing || isProcessingError || input.isEmpty) {
      if (!_isSuccessProcessing) setState(() {});
      return;
    }

    final targetIndex = _occlusion.firstHiddenIndex;
    if (targetIndex != null) {
      final targetWord = widget.state.currentPassage.words[targetIndex];
      // Allow checking as soon as we have enough chars for the *clean* word
      // e.g. target "don't" (5 chars) -> clean "dont" (4 chars)
      // We want to validate as soon as user types "dont"
      final requiredLength = _occlusion.getCleanMatchingLength(targetIndex);

      // Evaluate only when length matches target (or exceeds)
      if (input.length >= requiredLength) {
        // 1. Success: strict match (with tolerance)
        if (_occlusion.checkWord(targetIndex, input)) {
          _isSuccessProcessing = true;
          HapticFeedback.mediumImpact();
          final next = _occlusion.revealIndices({targetIndex});

          setState(() {
            _occlusion = next;
          });

          // Delay clearing to allow IME to settle (fixes iOS double-entry bug)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              inputController.clear();
              _isSuccessProcessing = false;
              setState(() {});
            }
          });

          if (next.visibleRatio >= 1.0) {
            widget.onContinue();
          }
          return;
        }

        // 2. Retry vs Failure check
        if (PassageValidator.isTypoRetry(targetWord, input)) {
          // 2. Retry
          // Flash red (automatic via isInputValid check) but keep input
          // Do not deduct life
          // Optional: Light feedback for typo warning?
          // HapticFeedback.selectionClick();
          setState(() {});
        } else {
          // 3. Failure
          HapticFeedback.heavyImpact();
          setState(() {
            isProcessingError = true;
          });

          // Delay penalty to allow user to see the error (red)
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _handleLifeLost(targetIndex);
              setState(() {
                isProcessingError = false;
              });
            }
          });
        }
      } else {
        // Typing in progress
        setState(() {});
      }
    }
  }

  void _handleLifeLost(int targetIndex) {
    inputController.clear();

    setState(() {
      _lives--;
    });
    widget.onLivesChange?.call(_lives);

    // Reveal the word as a penalty/assist
    final next = _occlusion.revealIndices({targetIndex});
    setState(() {
      _occlusion = next;
    });

    if (_lives <= 0) {
      _handleDeath();
    } else {
      if (next.visibleRatio >= 1.0) {
        widget.onContinue();
      }
    }
  }

  void _handleWordTap(int index) {
    // Ignore if already revealed or not hidden
    if (!_occlusion.isWordHidden(index)) return;

    // Clear input if tapping the active word
    if (index == _occlusion.firstHiddenIndex) {
      inputController.clear();
    }

    // Track as manually revealed (for neutral color)
    setState(() {
      _revealedIndices.add(index);
      _lives--;
    });
    widget.onLivesChange?.call(_lives);

    // Reveal the word
    final next = _occlusion.revealIndices({index});
    setState(() {
      _occlusion = next;
    });

    if (_lives <= 0) {
      _handleDeath();
    } else {
      if (next.visibleRatio >= 1.0) {
        widget.onContinue();
      }
    }
  }

  void _handleDeath() {
    if (widget.onRegress != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Out of lives! Stepping back...'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      // Capture current state for metrics
      final currentInput = inputController.text;
      // Use helper to get duration, or just pass 0 if not locally tracked strictly.
      // PracticeSessionView tracks total duration, but ScaffoldingScreen doesn't easily know "time spent in this specific attempt"
      // without extra state. For now passing 0, or we can use the mixin's timer if available.
      // TypingPracticeMixin doesn't expose a timer.
      // Note: PracticeController tracks session duration.
      widget.onRegress!(currentInput, 0);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Out of lives! Retrying with new pattern...'),
      ),
    );

    // Reset with new pattern
    setState(() {
      _lives = 2;
      _occlusion = _generateOcclusionForStep();
      _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);
      _revealedIndices = {}; // Clear revealed words
    });
    widget.onLivesChange?.call(_lives);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _occlusion.firstHiddenIndex;

    return Scaffold(
      backgroundColor: RedLetterColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (!focusNode.hasFocus) {
              focusNode.requestFocus();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type the missing words to complete the passage',
                            style: RedLetterTypography.promptText.copyWith(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: RedLetterColors.secondaryText,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 1,
                            height: 1,
                            child: TextField(
                              controller: inputController,
                              focusNode: focusNode,
                              autofocus: true,
                              onChanged: _onInputChange,
                              readOnly: isProcessingError,
                              autocorrect: true,
                              enableSuggestions: true,
                              showCursor: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              style: const TextStyle(color: Colors.transparent),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: pulseController,
                            builder: (context, _) {
                              return InlinePassageView(
                                passage: widget.state.currentPassage,
                                occlusion: _occlusion,
                                activeIndex: activeIndex,
                                // If success processing, show empty to avoid flashing old word on new active index
                                currentInput: _isSuccessProcessing
                                    ? ''
                                    : inputController.text,
                                isInputValid: isInputValid(
                                  _occlusion,
                                  widget.state.currentPassage,
                                ),
                                pulseAnimation: pulseAnimation,
                                originallyHiddenIndices:
                                    _originallyHiddenIndices,
                                onWordTap: _handleWordTap,
                                revealedIndices: _revealedIndices,
                                showUnderlines:
                                    widget.state.currentStep !=
                                    PracticeStep.fullPassage,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
