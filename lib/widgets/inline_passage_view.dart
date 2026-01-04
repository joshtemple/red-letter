import 'package:flutter/material.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/cloze_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

class InlinePassageView extends StatelessWidget {
  final Passage passage;
  final ClozeOcclusion occlusion;
  final int? activeIndex;
  final String currentInput;
  final bool isInputValid;
  final Animation<double> pulseAnimation;
  final Set<int> originallyHiddenIndices;
  final int? hintedIndex;
  final bool showUnderlines;
  final Function(int)? onWordTap; // Callback when a hidden word is tapped
  final Set<int> revealedIndices; // Track manually revealed words

  const InlinePassageView({
    super.key,
    required this.passage,
    required this.occlusion,
    this.activeIndex,
    this.currentInput = '',
    this.isInputValid = true,
    required this.pulseAnimation,
    required this.originallyHiddenIndices,
    this.hintedIndex,
    this.showUnderlines = true,
    this.onWordTap,
    this.revealedIndices = const {},
  });

  @override
  Widget build(BuildContext context) {
    final words = passage.words;
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final isHidden = occlusion.isWordHidden(i);
      final isLast = i == words.length - 1;

      if (isHidden) {
        final isIndexActive = i == activeIndex;
        final isHinted = i == hintedIndex;
        final targetWord = words[i];

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onWordTap != null && !isIndexActive
                  ? () => onWordTap!(i)
                  : null,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Reserve EXACT space of the target word
                  Text(
                    targetWord,
                    style: RedLetterTypography.passageBody.copyWith(
                      color: Colors.transparent,
                    ),
                  ),
                  // Drawn line at the bottom
                  // Drawn line at the bottom
                  if (showUnderlines || isIndexActive)
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2.0,
                        decoration: BoxDecoration(
                          color: isIndexActive
                              ? (isInputValid
                                    ? RedLetterColors.accent.withOpacity(
                                        pulseAnimation.value,
                                      )
                                    : RedLetterColors.error)
                              : RedLetterColors.divider.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  // Hint text (faded in)
                  if (isHinted)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, opacity, child) {
                        return Opacity(opacity: opacity, child: child);
                      },
                      child: Text(
                        targetWord,
                        key: const Key('hint_text'),
                        style: RedLetterTypography.passageBody.copyWith(
                          color: RedLetterColors.secondaryText.withOpacity(0.3),
                        ),
                      ),
                    ),
                  // Currently typed text for active word
                  if (isIndexActive)
                    Text(
                      currentInput,
                      key: const Key('typed_text'),
                      style: RedLetterTypography.passageBody.copyWith(
                        fontSize: 28, // Explicitly set to match passageBody
                        color: isInputValid
                            ? RedLetterColors.accent
                            : RedLetterColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Visible (revealed or originally visible)
        final wasHidden = originallyHiddenIndices.contains(i);
        final wasRevealed = revealedIndices.contains(i);

        spans.add(
          TextSpan(
            text: words[i],
            style: RedLetterTypography.passageBody.copyWith(
              // Revealed words: neutral/secondary color
              // Correctly typed words: green
              color: wasRevealed
                  ? RedLetterColors.secondaryText
                  : (wasHidden ? RedLetterColors.correct : null),
            ),
          ),
        );
      }

      // Add space if not last
      if (!isLast) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      key: const Key('passage_text'),
      textAlign: TextAlign.start,
      text: TextSpan(style: RedLetterTypography.passageBody, children: spans),
    );
  }
}
