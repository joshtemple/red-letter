import 'package:flutter/material.dart';

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
  final TextEditingController _inputController = TextEditingController();

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
    super.dispose();
  }

  void _handleInputChange(String input) {
    if (input.isEmpty) return;

    final newOcclusion = _occlusion.checkInput(input);
    if (newOcclusion != _occlusion) {
      setState(() {
        _occlusion = newOcclusion;
      });
      // Clear input on successful match (active tracking)
      _inputController.clear();
    }
  }

  bool get _isComplete {
    return _occlusion.visibleRatio >= 1.0;
  }

  String _getDisplayText() {
    return _occlusion.getDisplayText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Scaffolding', style: RedLetterTypography.modeTitle),
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
                      const SizedBox(height: 72),
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
                        controller: _inputController,
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
