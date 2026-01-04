import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_letter/mixins/typing_practice_mixin.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/theme/colors.dart';

import 'package:red_letter/widgets/inline_passage_view.dart';
import 'package:red_letter/utils/levenshtein.dart';

class ScaffoldingScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final ClozeOcclusion? occlusion;
  final ValueChanged<int>? onLivesChange;

  const ScaffoldingScreen({
    super.key,
    required this.state,
    required this.onContinue,
    this.occlusion,
    this.onLivesChange,
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
    _occlusion = widget.occlusion ?? _generateOcclusionForMode();
    _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);

    // Report initial lives to parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLivesChange?.call(_lives);
      focusNode.requestFocus();
    });
  }

  // ... (omitted methods _generateOcclusionForMode, _isComplete, _onInputChange same as before)

  ClozeOcclusion _generateOcclusionForMode() {
    final passage = widget.state.currentPassage;
    switch (widget.state.currentMode) {
      case PracticeMode.randomWords:
        return ClozeOcclusion.randomWordPerClause(passage: passage);
      case PracticeMode.rotatingClauses:
        return ClozeOcclusion.rotatingClauseDeletion(
          passage: passage,
          clauseIndex: 0,
        );
      case PracticeMode.firstTwoWords:
        return ClozeOcclusion.firstTwoWordsScaffolding(passage: passage);
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
      final requiredLength = _occlusion.getMatchingLength(targetIndex);

      // Evaluate only when length matches target (or exceeds)
      if (input.length >= requiredLength) {
        // 1. Success: strict match
        if (_occlusion.checkWord(targetIndex, input, maxDistance: 0)) {
          _isSuccessProcessing = true;
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

        // Calculate distance for Retry vs Failure
        // We use lowercased comparison for distance check
        final distance = levenshtein(
          input.toLowerCase(),
          targetWord.toLowerCase(),
        );

        // Define threshold: 1 for short words, 2 for longer
        final threshold = targetWord.length <= 3 ? 1 : 2;

        if (distance <= threshold) {
          // 2. Retry
          // Flash red (automatic via isInputValid check) but keep input
          // Do not deduct life
          setState(() {});
        } else {
          // 3. Failure
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Out of lives! Retrying with new pattern...'),
      ),
    );

    // Reset with new pattern
    setState(() {
      _lives = 2;
      _occlusion = _generateOcclusionForMode();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                              originallyHiddenIndices: _originallyHiddenIndices,
                              onWordTap: _handleWordTap,
                              revealedIndices: _revealedIndices,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
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
