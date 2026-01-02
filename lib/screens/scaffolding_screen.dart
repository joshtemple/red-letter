import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_letter/mixins/typing_practice_mixin.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/practice_footer.dart';
import 'package:red_letter/widgets/inline_passage_view.dart';

class ScaffoldingScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final VoidCallback onReset;
  final WordOcclusion? occlusion;

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
  late WordOcclusion _occlusion;
  late Set<int> _originallyHiddenIndices;

  @override
  void initState() {
    super.initState();
    _occlusion =
        widget.occlusion ??
        WordOcclusion.generate(passage: widget.state.currentPassage);
    _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void _onInputChange(String input) {
    handleInputChange(
      input: input,
      currentOcclusion: _occlusion,
      passage: widget.state.currentPassage,
      onWordMatched: (next) {
        setState(() {
          _occlusion = next;
        });
      },
      onComplete: widget.onContinue,
      onStateChanged: () => setState(() {}),
    );
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
    );
  }
}
