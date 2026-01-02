import 'package:flutter/material.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

class PassageListItem extends StatelessWidget {
  final PassageWithProgress passageWithProgress;
  final VoidCallback onTap;

  const PassageListItem({
    super.key,
    required this.passageWithProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // This 'passage' is the Drift Row class
    final passage = passageWithProgress.passage;
    final masteryLevel = passageWithProgress.masteryLevel;

    // Mastery Colors based on level 0-5
    // 0: Grey (New), 1-4: Progressing Gold/Green
    // 5: Mastered (Green)
    // For now, let's use a simple progression of opacity/color
    Color masteryColor;
    if (masteryLevel == 0) {
      masteryColor = RedLetterColors.tertiaryText.withOpacity(0.3);
    } else if (masteryLevel >= 5) {
      masteryColor = RedLetterColors.correct;
    } else {
      masteryColor = RedLetterColors.accent;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mastery Indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: masteryColor, width: 2.0),
                color: masteryLevel >= 5
                    ? masteryColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  masteryLevel.toString(),
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: masteryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Passage Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passage.reference,
                    style: RedLetterTypography.passageReference.copyWith(
                      color: RedLetterColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passage.passageText, // Drift uses passageText
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RedLetterTypography.passageBody.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: RedLetterColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: RedLetterColors.tertiaryText.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
