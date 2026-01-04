import 'package:flutter/material.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

class PracticeFooter extends StatelessWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onHint;
  final bool continueEnabled;
  final String continueLabel;

  const PracticeFooter({
    super.key,
    this.onContinue,
    this.onHint,
    this.continueEnabled = true,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, top: 24.0),
      child: Row(
        children: [
          if (onContinue != null) ...[
            const SizedBox(width: 12),
            // Continue Button
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  key: const Key('continue_button'),
                  onPressed: continueEnabled ? onContinue : null,
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
                    continueLabel,
                    style: RedLetterTypography.modeTitle.copyWith(
                      color: continueEnabled
                          ? Colors.white
                          : RedLetterColors.tertiaryText,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (onHint != null) ...[
            const SizedBox(width: 12),
            // Hint Button
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: onHint,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: RedLetterColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: RedLetterColors.accent,
                  ),
                  child: const Icon(Icons.lightbulb_outline),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
