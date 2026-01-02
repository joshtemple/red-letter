import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

class PromptedScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;

  const PromptedScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<PromptedScreen> createState() => _PromptedScreenState();
}

class _PromptedScreenState extends State<PromptedScreen> {
  late TextEditingController _controller;
  String _userInput = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleInputChange(String input) {
    setState(() {
      _userInput = input;
    });
  }

  bool get _isComplete {
    return PassageValidator.isLenientMatch(
      widget.state.currentPassage.text,
      _userInput,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Prompted', style: RedLetterTypography.modeTitle),
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
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Type the passage from memory:',
                        style: RedLetterTypography.promptText,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.state.currentPassage.reference,
                        style: RedLetterTypography.passageReference,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _controller,
                        onChanged: _handleInputChange,
                        maxLines: null,
                        style: RedLetterTypography.userInputText,
                        decoration: InputDecoration(
                          hintText: 'Start typing...',
                          hintStyle: RedLetterTypography.hintText,
                          border: InputBorder.none,
                          // Optional: visual feedback
                        ),
                        autofocus: true,
                        enableSuggestions: false,
                        autocorrect: false,
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
