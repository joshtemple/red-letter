import 'package:flutter/material.dart';
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

  const PassageInput({
    super.key,
    this.text = '',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.hintText,
    this.useMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
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
