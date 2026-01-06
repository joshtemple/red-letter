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
        final parts = ClozeOcclusion.parseWordParts(words[i]);

        // 1. Prefix (Punctuation)
        if (parts.prefix.isNotEmpty) {
          spans.add(
            TextSpan(
              text: parts.prefix,
              style: RedLetterTypography.passageBody,
            ),
          );
        }

        // 2. Content (The hidden word)
        if (parts.content.isNotEmpty) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: onWordTap != null ? () => onWordTap!(i) : null,
                child: _HiddenContent(
                  text: parts.content,
                  input: isIndexActive ? currentInput : '',
                  isActive: isIndexActive,
                  isValid: isInputValid,
                  isHinted: isHinted,
                  animation: pulseAnimation,
                  showUnderline: showUnderlines || isIndexActive,
                ),
              ),
            ),
          );
        }

        // 3. Suffix (Punctuation)
        if (parts.suffix.isNotEmpty) {
          spans.add(
            TextSpan(
              text: parts.suffix,
              style: RedLetterTypography.passageBody,
            ),
          );
        }
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

class _HiddenContent extends StatelessWidget {
  final String text;
  final String input;
  final bool isActive;
  final bool isValid;
  final bool isHinted;
  final Animation<double> animation;
  final bool showUnderline;

  const _HiddenContent({
    required this.text,
    required this.input,
    required this.isActive,
    required this.isValid,
    required this.isHinted,
    required this.animation,
    required this.showUnderline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 1. Invisible text to reserve exact width
        Text(
          text,
          style: RedLetterTypography.passageBody.copyWith(
            color: Colors.transparent,
          ),
        ),

        // 2. Continuous underline
        if (showUnderline)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Container(
              height: 2.0,
              decoration: BoxDecoration(
                color: isActive
                    ? (isValid
                          ? RedLetterColors.accent.withOpacity(animation.value)
                          : RedLetterColors.error)
                    : RedLetterColors.divider.withOpacity(0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

        // 3. Hint text (faded in)
        if (isHinted)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, opacity, child) {
              return Opacity(opacity: opacity, child: child);
            },
            child: Text(
              text,
              key: const Key('hint_text'),
              style: RedLetterTypography.passageBody.copyWith(
                color: RedLetterColors.secondaryText.withOpacity(0.3),
              ),
            ),
          ),

        // 4. Currently typed text for active word
        if (isActive && input.isNotEmpty)
          Text(
            input,
            key: const Key('typed_text'),
            style: RedLetterTypography.passageBody.copyWith(
              fontSize: 28, // Explicitly set to match passageBody
              color: isValid ? RedLetterColors.accent : RedLetterColors.error,
            ),
          ),
      ],
    );
  }
}
