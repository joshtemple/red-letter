import 'package:flutter/material.dart';

class RedLetterTypography {
  RedLetterTypography._();

  static const String _serifFontFamily = 'Georgia';
  static const String _sansFontFamily = 'SF Pro Text';
  static const String _monoFontFamily = 'SF Mono';

  static const Color _primaryTextColor = Color(0xFF1A1A1A);
  static const Color _secondaryTextColor = Color(0xFF666666);
  static const Color _inputTextColor = Color(0xFF2C2C2C);

  static const TextStyle passageBody = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 22,
    height: 1.6,
    letterSpacing: 0.15,
    color: _primaryTextColor,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
  );

  static const TextStyle passageReference = TextStyle(
    fontFamily: _sansFontFamily,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 0.1,
    color: _secondaryTextColor,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
  );

  static const TextStyle userInputText = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 22,
    height: 1.6,
    letterSpacing: 0.15,
    color: _inputTextColor,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
  );

  static const TextStyle userInputTextMonospace = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 20,
    height: 1.5,
    letterSpacing: 0,
    color: _inputTextColor,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
  );

  static const TextStyle modeTitle = TextStyle(
    fontFamily: _sansFontFamily,
    fontSize: 16,
    height: 1.3,
    letterSpacing: 0.5,
    color: _secondaryTextColor,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );

  static const TextStyle promptText = TextStyle(
    fontFamily: _sansFontFamily,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.1,
    color: _primaryTextColor,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
  );

  static const TextStyle hintText = TextStyle(
    fontFamily: _sansFontFamily,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFF999999),
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    decoration: TextDecoration.none,
  );

  static TextStyle get passageBodyWithShadow => passageBody.copyWith(
        shadows: const [
          Shadow(
            color: Color(0x08000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      );
}
