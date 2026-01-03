import 'package:flutter_test/flutter_test.dart';
import 'base_page.dart';

class ImpressionPage extends BasePage {
  ImpressionPage(super.tester);

  void expectPassageText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  void expectReference(String reference) {
    expect(find.text(reference), findsOneWidget);
  }
}
