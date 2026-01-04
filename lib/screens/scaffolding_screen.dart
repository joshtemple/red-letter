import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_letter/mixins/typing_practice_mixin.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/practice_footer.dart';
import 'package:red_letter/widgets/inline_passage_view.dart';

class ScaffoldingScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final VoidCallback onReset;
  final ClozeOcclusion? occlusion;

  const ScaffoldingScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
    this.occlusion,
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

  @override
  void initState() {
    super.initState();
    _occlusion = widget.occlusion ?? _generateOcclusionForMode();
    _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

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

  bool get _isComplete {
    return _occlusion.visibleRatio >= 1.0;
  }

  void _onInputChange(String input) {
    if (isProcessingError || input.isEmpty) {
      setState(() {});
      return;
    }

    final targetIndex = _occlusion.firstHiddenIndex;
    if (targetIndex != null) {
      if (_occlusion.checkWord(targetIndex, input)) {
        // Correct input
        final next = _occlusion.revealIndices({targetIndex});
        inputController.clear();
        setState(() {
          _occlusion = next;
        });

        if (next.visibleRatio >= 1.0) {
          widget.onContinue();
        }
      } else {
        // Validate input for errors
        final targetWord = widget.state.currentPassage.words[targetIndex];

        // Be more lenient with typos - only penalize if clearly wrong
        // Allow 1 extra character for typos (e.g., "lovve" for "love")
        if (input.length > targetWord.length + 1) {
          setState(() {
            isProcessingError = true;
          });

          // Delay penalty to allow user to see the error
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _handleLifeLost(targetIndex);
              setState(() {
                isProcessingError = false;
              });
            }
          });
        } else {
          // Incomplete word or close typo, just update UI (red text if mismatch)
          setState(() {});
        }
      }
    }
  }

  void _handleLifeLost(int targetIndex) {
    inputController.clear();

    setState(() {
      _lives--;
    });

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
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _occlusion.firstHiddenIndex;

    return Scaffold(
      backgroundColor: RedLetterColors.background,
      body: Stack(
        children: [
          SafeArea(
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
                        const SizedBox(height: 72),
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: TextField(
                            controller: inputController,
                            focusNode: focusNode,
                            autofocus: true,
                            onChanged: _onInputChange,
                            readOnly: isProcessingError,
                            autocorrect: false,
                            enableSuggestions: false,
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
                              currentInput: inputController.text,
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
                PracticeFooter(
                  onReset: widget.onReset,
                  onContinue: widget.onContinue,
                  continueEnabled: _isComplete,
                ),
              ],
            ),
          ),
        ),
      ),
          // Lives indicator overlay in top-right
          SafeArea(
            child: Positioned(
              top: 8,
              right: 16,
              child: Row(
                children: [
                  Icon(
                    _lives >= 1 ? Icons.favorite : Icons.favorite_border,
                    color: RedLetterColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _lives >= 2 ? Icons.favorite : Icons.favorite_border,
                    color: RedLetterColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
