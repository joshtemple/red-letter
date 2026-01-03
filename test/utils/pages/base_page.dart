import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Base class for Page Objects.
///
/// Encapsulates common [WidgetTester] interacts to ensure tests are readable
/// and decoupled from low-level finder logic.
abstract class BasePage {
  final WidgetTester tester;

  BasePage(this.tester);

  Future<void> pumpAndSettle() async {
    await tester.pumpAndSettle();
  }

  Future<void> pump([Duration? duration]) async {
    await tester.pump(duration);
  }

  /// Helper to tap a widget by key.
  Future<void> tapKey(Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  /// Helper to tap a widget by text.
  Future<void> tapText(String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
  }

  /// Helper to tap a widget by icon.
  Future<void> tapIcon(IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pump();
  }

  /// Taps the 'Continue' button in the footer.
  Future<void> tapContinue() async {
    await tester.tap(find.byKey(const Key('continue_button')));
    await tester.pump();
  }

  /// Taps the 'Reset' button in the footer.
  Future<void> tapReset() async {
    await tester.tap(find.byKey(const Key('reset_button')));
    await tester.pump();
  }
}
