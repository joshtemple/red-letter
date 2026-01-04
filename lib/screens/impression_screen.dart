import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';
import 'package:red_letter/widgets/practice_footer.dart';

class ImpressionScreen extends StatelessWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final VoidCallback onReset;

  const ImpressionScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                state.currentPassage.reference,
                style: RedLetterTypography.passageReference,
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Read this passage aloud twice',
                          style: RedLetterTypography.promptText.copyWith(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: RedLetterColors.secondaryText,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 32),
                        PassageText(
                          passage: state.currentPassage,
                          textAlign: TextAlign.start,
                          showReference: false, // Moved to AppBar
                          enableShadow: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PracticeFooter(onReset: onReset, onContinue: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}
