import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/theme/colors.dart';
import 'base_page.dart';

class PromptedPage extends BasePage {
  PromptedPage(super.tester);

  Finder get _textField => find.byType(TextField);

  Finder get _typedText => find.byKey(const Key('typed_text'));

  Future<void> enterText(String text) async {
    await tester.enterText(_textField.last, text);
    await tester.pump();
  }

  void expectTextFieldVisible() {
    expect(_textField, findsWidgets);
  }

  void expectInputCleared() {
    final textField = tester.widget<TextField>(_textField.last);
    expect(textField.controller?.text, isEmpty);
  }

  void expectInputText(String text) {
    final textField = tester.widget<TextField>(_textField.last);
    expect(textField.controller?.text, equals(text));
  }

  void expectTypedTextIsError() {
    final textWidget = tester.widget<Text>(_typedText);
    expect(textWidget.style?.color, RedLetterColors.error);
  }

  void expectTypedTextIsNotError() {
    final textWidget = tester.widget<Text>(_typedText);
    expect(textWidget.style?.color, isNot(RedLetterColors.error));
  }
}
