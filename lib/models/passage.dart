class Passage {
  final String id;
  final String text;
  final String reference;
  final List<String> words;

  const Passage({
    required this.id,
    required this.text,
    required this.reference,
    required this.words,
  });

  factory Passage.fromText({
    required String id,
    required String text,
    required String reference,
  }) {
    final words = _tokenize(text);
    return Passage(
      id: id,
      text: text,
      reference: reference,
      words: words,
    );
  }

  factory Passage.fromJson(Map<String, dynamic> json) {
    return Passage(
      id: json['id'] as String,
      text: json['text'] as String,
      reference: json['reference'] as String,
      words: (json['words'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'reference': reference,
      'words': words,
    };
  }

  static List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  Passage copyWith({
    String? id,
    String? text,
    String? reference,
    List<String>? words,
  }) {
    return Passage(
      id: id ?? this.id,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      words: words ?? this.words,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Passage &&
        other.id == id &&
        other.text == text &&
        other.reference == reference;
  }

  @override
  int get hashCode {
    return Object.hash(id, text, reference);
  }

  @override
  String toString() {
    return 'Passage(id: $id, reference: $reference, wordCount: ${words.length})';
  }
}
