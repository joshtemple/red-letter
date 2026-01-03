import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'base_page.dart';

class PromptedPage extends BasePage {
  PromptedPage(super.tester);

  Finder get _textField => find.byType(TextField);

  Future<void> enterText(String text) async {
    await tester.enterText(_textField.last, text);
    await tester.pump();
  }

  void expectTextFieldVisible() {
    expect(_textField, findsWidgets);
  }
}
