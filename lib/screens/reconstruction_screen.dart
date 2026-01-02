import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

class ReconstructionScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;

  const ReconstructionScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<ReconstructionScreen> createState() => _ReconstructionScreenState();
}

class _ReconstructionScreenState extends State<ReconstructionScreen> {
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
    return PassageValidator.isStrictMatch(
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
        title: Text('Reconstruction', style: RedLetterTypography.modeTitle),
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
                        textAlign: TextAlign
                            .center, // Center align for "Mastery" feel?
                        decoration: InputDecoration(
                          hintText: 'Type the passage...',
                          hintStyle: RedLetterTypography.hintText,
                          border: InputBorder.none,
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
