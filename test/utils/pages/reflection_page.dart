import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'base_page.dart';

class ReflectionPage extends BasePage {
  ReflectionPage(super.tester);

  Finder get _textField => find.byType(TextField);

  Future<void> enterReflection(String text) async {
    await tester.enterText(_textField.last, text);
    await tester.pump();
  }
}
