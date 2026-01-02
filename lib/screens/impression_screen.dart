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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          state.currentPassage.reference,
          style: RedLetterTypography.passageReference,
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
                        PassageText(
                          passage: state.currentPassage,
                          textAlign: TextAlign.center,
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
