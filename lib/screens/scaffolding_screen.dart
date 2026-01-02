import 'package:flutter/material.dart';

import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

class ScaffoldingScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final WordOcclusion? occlusion; // Optional for testing

  const ScaffoldingScreen({
    super.key,
    required this.state,
    required this.onContinue,
    this.occlusion,
  });

  @override
  State<ScaffoldingScreen> createState() => _ScaffoldingScreenState();
}

class _ScaffoldingScreenState extends State<ScaffoldingScreen> {
  late WordOcclusion _occlusion;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _occlusion =
        widget.occlusion ??
        WordOcclusion.generate(passage: widget.state.currentPassage);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleInputChange(String input) {
    if (input.isEmpty) {
      setState(() {}); // Update to show empty cursor
      return;
    }

    final targetIndex = _occlusion.firstHiddenIndex;
    if (targetIndex != null) {
      if (_occlusion.checkWord(targetIndex, input)) {
        // Match found!
        final nextOcclusion = _occlusion.revealIndices({targetIndex});
        setState(() {
          _occlusion = nextOcclusion;
          _inputController.clear();
        });

        // Auto-advance if complete
        if (nextOcclusion.visibleRatio >= 1.0) {
          widget.onContinue();
        }
      } else {
        // No match, just update state to show typing
        setState(() {});
      }
    }
  }

  bool get _isComplete {
    return _occlusion.visibleRatio >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the active word index for inline rendering
    final activeIndex = _occlusion.firstHiddenIndex;

    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Scaffolding', style: RedLetterTypography.modeTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Tapping anywhere focuses the hidden input to ensure keyboard is up
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
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
                        // Hidden input field to capture typing
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: TextField(
                            controller: _inputController,
                            focusNode: _focusNode,
                            autofocus: true,
                            onChanged: _handleInputChange,
                            autocorrect: false,
                            enableSuggestions: false,
                            // Hide the cursor and text
                            showCursor: false,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            style: const TextStyle(color: Colors.transparent),
                          ),
                        ),
                        _buildInlinePassage(activeIndex),
                        const SizedBox(height: 24),
                        Text(
                          widget.state.currentPassage.reference,
                          textAlign: TextAlign.center,
                          style: RedLetterTypography.passageReference,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, top: 24.0),
                  child: _ContinueButton(
                    onPressed: widget.onContinue,
                    enabled: _isComplete,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlinePassage(int? activeIndex) {
    final words = widget.state.currentPassage.words;
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final isHidden = _occlusion.isWordHidden(i);
      final isLast = i == words.length - 1;

      if (isHidden) {
        if (i == activeIndex) {
          // Active word being typed
          final targetWordLength = words[i].length;
          final currentInput = _inputController.text;

          // Ensure we don't overflow if the user somehow types more than the word
          // though checkWord would usually clear it or ignore it.
          final displayText = currentInput.length >= targetWordLength
              ? currentInput
              : currentInput.padRight(targetWordLength, '_');

          spans.add(
            TextSpan(
              text: displayText,
              style: RedLetterTypography.passageBody.copyWith(
                color: RedLetterColors.accent,
                decoration: TextDecoration.underline,
                decorationColor: RedLetterColors.accent.withOpacity(0.5),
              ),
            ),
          );
        } else {
          // Future hidden word
          spans.add(
            TextSpan(
              text: '_' * words[i].length,
              style: RedLetterTypography.passageBody.copyWith(
                color: RedLetterColors.divider, // Faded for future words?
              ),
            ),
          );
        }
      } else {
        // Visible (revealed or originally visible)
        spans.add(
          TextSpan(text: words[i], style: RedLetterTypography.passageBody),
        );
      }

      // Add space if not last
      if (!isLast) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      key: const Key('passage_text'),
      textAlign: TextAlign.center,
      text: TextSpan(
        style: RedLetterTypography.passageBody, // Default style
        children: spans,
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _ContinueButton({required this.onPressed, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: RedLetterColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: RedLetterColors.divider,
          disabledForegroundColor: RedLetterColors.tertiaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Continue',
          style: RedLetterTypography.modeTitle.copyWith(
            color: enabled ? Colors.white : RedLetterColors.tertiaryText,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
