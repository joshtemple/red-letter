import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'base_page.dart';

class ReconstructionPage extends BasePage {
  ReconstructionPage(super.tester);

  Finder get _textField => find.byType(TextField);

  Future<void> enterText(String text) async {
    await tester.enterText(_textField.last, text);
    await tester.pump();
  }

  void expectResetButtonVisible() {
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  }
}
