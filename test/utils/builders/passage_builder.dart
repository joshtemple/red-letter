import 'package:red_letter/models/passage.dart';

/// Test Data Builder for [Passage] model.
///
/// Usage:
/// ```dart
/// final passage = PassageBuilder()
///   .withId('mat-5-44')
///   .withText('Love your enemies')
///   .build();
/// ```
class PassageBuilder {
  String _id = 'test-passage-id';
  String _text = 'Test passage text.';
  String _reference = 'Test 1:1';

  PassageBuilder withId(String id) {
    _id = id;
    return this;
  }

  PassageBuilder withText(String text) {
    _text = text;
    return this;
  }

  PassageBuilder withReference(String reference) {
    _reference = reference;
    return this;
  }

  Passage build() {
    return Passage.fromText(id: _id, text: _text, reference: _reference);
  }
}
