import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';

class ImpressionScreen extends StatelessWidget {
  final PracticeState state;
  final VoidCallback onContinue;

  const ImpressionScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Impression',
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
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _MnemonicPlaceholder(),
                        const SizedBox(height: 48),
                        PassageText(
                          passage: state.currentPassage,
                          textAlign: TextAlign.center,
                          showReference: true,
                          enableShadow: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0, top: 24.0),
                child: _ContinueButton(onPressed: onContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MnemonicPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: RedLetterColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RedLetterColors.divider,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: RedLetterColors.tertiaryText,
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: RedLetterColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Continue',
          style: RedLetterTypography.modeTitle.copyWith(
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
