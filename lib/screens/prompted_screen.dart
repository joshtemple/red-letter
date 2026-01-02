import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_letter/mixins/typing_practice_mixin.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/practice_footer.dart';
import 'package:red_letter/widgets/inline_passage_view.dart';

class PromptedScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final VoidCallback onReset;

  const PromptedScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
  });

  @override
  State<PromptedScreen> createState() => _PromptedScreenState();
}

class _PromptedScreenState extends State<PromptedScreen>
    with TickerProviderStateMixin, TypingPracticeMixin {
  late WordOcclusion _occlusion;
  int? _hintedIndex;

  @override
  void initState() {
    super.initState();
    // Prompted mode: all words are hidden initially
    final allIndices = Set<int>.from(
      List.generate(widget.state.currentPassage.words.length, (i) => i),
    );
    _occlusion = WordOcclusion.manual(
      passage: widget.state.currentPassage,
      hiddenIndices: allIndices,
    );
  }

  void _onInputChange(String input) {
    handleInputChange(
      input: input,
      currentOcclusion: _occlusion,
      passage: widget.state.currentPassage,
      onWordMatched: (next) {
        setState(() {
          _occlusion = next;
          _hintedIndex = null; // Clear hint when word is matched
        });
      },
      onComplete: widget.onContinue,
      onStateChanged: () => setState(() {}),
    );
  }

  void _showHint() {
    setState(() {
      _hintedIndex = _occlusion.firstHiddenIndex;
    });

    // Return focus to the input immediately so typing can continue
    focusNode.requestFocus();
  }

  bool get _isComplete {
    return _occlusion.visibleRatio >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _occlusion.firstHiddenIndex;

    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.state.currentPassage.reference,
          style: RedLetterTypography.passageReference,
        ),
        centerTitle: true,
      ),
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
                      children: [
                        const SizedBox(height: 72),
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
                PracticeFooter(
                  onReset: widget.onReset,
                  onContinue: widget.onContinue,
                  onHint: _showHint,
                  continueEnabled: _isComplete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
