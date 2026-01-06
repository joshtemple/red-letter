import 'package:flutter/material.dart';
import 'package:red_letter/models/clause_segmentation.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/theme/typography.dart';

class PassageText extends StatelessWidget {
  final Passage passage;
  final TextAlign textAlign;
  final bool showReference;
  final bool enableShadow;

  const PassageText({
    super.key,
    required this.passage,
    this.textAlign = TextAlign.left,
    this.showReference = true,
    this.enableShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReference) ...[
            Text(
              passage.reference,
              style: RedLetterTypography.passageReference,
              textAlign: textAlign,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            passage.text,
            style: enableShadow
                ? RedLetterTypography.passageBodyWithShadow
                : RedLetterTypography.passageBody,
            textAlign: textAlign,
          ),
        ],
      ),
    );
  }
}

class PassageInput extends StatelessWidget {
  final String text;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final bool useMonospace;
  final bool autofocus;

  const PassageInput({
    super.key,
    this.text = '',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.hintText,
    this.useMonospace = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        autofocus: autofocus,
        style: useMonospace
            ? RedLetterTypography.userInputTextMonospace
            : RedLetterTypography.userInputText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: RedLetterTypography.hintText,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: null,
        autocorrect: false,
        enableSuggestions: false,
      ),
    );
  }
}

class RevealablePassageText extends StatelessWidget {
  final Passage passage;
  final ClauseSegmentation segmentation;
  final int revealedClauseCount;
  final Animation<double> fadeAnimation;
  final TextAlign textAlign;
  final bool enableShadow;

  const RevealablePassageText({
    super.key,
    required this.passage,
    required this.segmentation,
    required this.revealedClauseCount,
    required this.fadeAnimation,
    this.textAlign = TextAlign.left,
    this.enableShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = enableShadow
        ? RedLetterTypography.passageBodyWithShadow
        : RedLetterTypography.passageBody;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: fadeAnimation,
        builder: (context, child) {
          final spans = <InlineSpan>[];

          for (int i = 0; i < revealedClauseCount && i < segmentation.clauseCount; i++) {
            final clause = segmentation.clauses[i];
            final isLastRevealed = i == revealedClauseCount - 1;

            if (isLastRevealed) {
              // Animate the most recently revealed clause
              spans.add(WidgetSpan(
                child: Opacity(
                  opacity: fadeAnimation.value,
                  child: Text(clause.text, style: textStyle),
                ),
              ));
            } else {
              // Already revealed, show without animation
              spans.add(TextSpan(text: clause.text, style: textStyle));
            }

            // Add space between clauses (not after last)
            if (i < revealedClauseCount - 1) {
              spans.add(const TextSpan(text: ' '));
            }
          }

          return Text.rich(
            TextSpan(children: spans),
            textAlign: textAlign,
          );
        },
      ),
    );
  }
}
