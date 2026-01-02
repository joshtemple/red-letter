import 'package:flutter/material.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';

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
  late Set<int> _revealedIndices;
  String _userInput = '';

  @override
  void initState() {
    super.initState();
    _occlusion = widget.occlusion ??
        WordOcclusion.generate(passage: widget.state.currentPassage);
    _revealedIndices = {};
  }

  void _handleInputChange(String input) {
    setState(() {
      _userInput = input.trim();
      _updateRevealedWords();
    });
  }

  void _updateRevealedWords() {
    if (_userInput.isEmpty) return;

    final inputWords = _userInput.toLowerCase().split(RegExp(r'\s+'));
    final passage = widget.state.currentPassage;

    // Check each hidden word to see if it matches any input word
    for (int i = 0; i < passage.words.length; i++) {
      if (_occlusion.isWordHidden(i) && !_revealedIndices.contains(i)) {
        final targetWord = passage.words[i].toLowerCase();
        if (inputWords.contains(targetWord)) {
          _revealedIndices.add(i);
        }
      }
    }
  }

  bool get _isComplete {
    return _revealedIndices.length == _occlusion.hiddenWordCount;
  }

  String _getDisplayText() {
    final words = <String>[];
    for (int i = 0; i < widget.state.currentPassage.words.length; i++) {
      if (_occlusion.isWordHidden(i)) {
        if (_revealedIndices.contains(i)) {
          // Show the actual word if revealed
          words.add(widget.state.currentPassage.words[i]);
        } else {
          // Show underscore placeholder if still hidden
          words.add(_occlusion.getDisplayWord(i));
        }
      } else {
        // Show visible words
        words.add(widget.state.currentPassage.words[i]);
      }
    }
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Scaffolding',
          style: RedLetterTypography.modeTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _ProgressIndicator(
                        revealed: _revealedIndices.length,
                        total: _occlusion.hiddenWordCount,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        _getDisplayText(),
                        textAlign: TextAlign.center,
                        style: RedLetterTypography.passageBody,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.state.currentPassage.reference,
                        textAlign: TextAlign.center,
                        style: RedLetterTypography.passageReference,
                      ),
                      const SizedBox(height: 48),
                      PassageInput(
                        hintText: 'Type the missing words...',
                        onChanged: _handleInputChange,
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
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int revealed;
  final int total;

  const _ProgressIndicator({
    required this.revealed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? revealed / total : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: RedLetterColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    RedLetterColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$revealed / $total words revealed',
          style: RedLetterTypography.passageReference.copyWith(
            fontSize: 14,
            color: RedLetterColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _ContinueButton({
    required this.onPressed,
    required this.enabled,
  });

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
