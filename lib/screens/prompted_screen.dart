import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_letter/mixins/typing_practice_mixin.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/theme/colors.dart';

import 'package:red_letter/widgets/practice_footer.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/widgets/inline_passage_view.dart';

class PromptedScreen extends StatefulWidget {
  final PracticeState state;
  final Function(String) onContinue;

  const PromptedScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<PromptedScreen> createState() => _PromptedScreenState();
}

class _PromptedScreenState extends State<PromptedScreen>
    with TickerProviderStateMixin, TypingPracticeMixin {
  late ClozeOcclusion _occlusion;
  int? _hintedIndex;

  @override
  void initState() {
    super.initState();
    // Prompted mode: all words are hidden initially
    final allIndices = Set<int>.from(
      List.generate(widget.state.currentPassage.words.length, (i) => i),
    );
    _occlusion = ClozeOcclusion.manual(
      passage: widget.state.currentPassage,
      hiddenIndices: allIndices,
    );

    // Ensure input is focused immediately after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  void _onInputChange(String input) {
    if (isSuccessProcessing || isProcessingError || input.isEmpty) {
      if (!isSuccessProcessing) setState(() {});
      return;
    }

    final targetIndex = _occlusion.firstHiddenIndex;
    if (targetIndex != null) {
      final targetWord = widget.state.currentPassage.words[targetIndex];
      final requiredLength = _occlusion.getMatchingLength(targetIndex);

      if (input.length >= requiredLength) {
        // 1. Success
        if (_occlusion.checkWord(targetIndex, input)) {
          isSuccessProcessing = true;
          final next = _occlusion.revealIndices({targetIndex});

          setState(() {
            _occlusion = next;
            _hintedIndex = null;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              inputController.clear();
              isSuccessProcessing = false;
              setState(() {});
            }
          });

          if (next.visibleRatio >= 1.0) {
            widget.onContinue(input);
          }
          return;
        }

        // 2. Retry vs Failure check
        if (PassageValidator.isTypoRetry(targetWord, input)) {
          // Retry: keep input (visual feedback handled by isInputValid returning false)
          setState(() {});
        } else {
          // 3. Failure: clear input
          setState(() {
            isProcessingError = true;
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              inputController.clear();
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

  void _showHint() {
    setState(() {
      _hintedIndex = _occlusion.firstHiddenIndex;
    });

    // Return focus to the input immediately so typing can continue
    focusNode.requestFocus();
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hidden input field
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: TextField(
                            controller: inputController,
                            focusNode: focusNode,
                            onChanged: _onInputChange,
                            autofocus: true,
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
                              currentInput: isSuccessProcessing
                                  ? ''
                                  : inputController.text,
                              isInputValid: isInputValid(
                                _occlusion,
                                widget.state.currentPassage,
                              ),
                              pulseAnimation: pulseAnimation,
                              originallyHiddenIndices: const {},
                              hintedIndex: _hintedIndex,
                              showUnderlines: false,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                PracticeFooter(onContinue: null, onHint: _showHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
