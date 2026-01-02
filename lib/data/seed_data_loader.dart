import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart';
import 'package:red_letter/data/database/app_database.dart';

class PassageSeedData {
  final String passageId;
  final String reference;
  final String text;
  final String tags;
  final String? mnemonicUrl;
  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;

  const PassageSeedData({
    required this.passageId,
    required this.reference,
    required this.text,
    required this.tags,
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    this.mnemonicUrl,
  });

  factory PassageSeedData.fromJson(Map<String, dynamic> json) {
    // Check if JSON has the new fields
    String? book = json['book'] as String?;
    int? chapter = json['chapter'] as int?;
    int? startVerse = json['start_verse'] as int?;
    int? endVerse = json['end_verse'] as int?;

    if (book == null ||
        chapter == null ||
        startVerse == null ||
        endVerse == null) {
      // Parse from reference string "Matthew 5:3" or "Matthew 5:3-10"
      // or "1 John 1:9"
      final ref = json['reference'] as String;

      try {
        // Last part is verse range
        final colonIndex = ref.lastIndexOf(':');
        if (colonIndex != -1) {
          final chapterStart = ref.lastIndexOf(' ', colonIndex);
          final chapterNum = int.parse(
            ref.substring(chapterStart + 1, colonIndex),
          );
          book = ref.substring(0, chapterStart);
          chapter = chapterNum;

          final versePart = ref.substring(colonIndex + 1);
          if (versePart.contains('-')) {
            final verses = versePart.split('-');
            startVerse = int.parse(verses[0]);
            endVerse = int.parse(verses[1]);
          } else {
            startVerse = int.parse(versePart);
            endVerse = startVerse;
          }
        } else {
          // Fallback for weird formats, though standard format is expected
          book = "";
          chapter = 0;
          startVerse = 0;
          endVerse = 0;
        }
      } catch (e) {
        // Parsing failed
        book = "";
        chapter = 0;
        startVerse = 0;
        endVerse = 0;
      }
    }

    return PassageSeedData(
      passageId: json['passage_id'] as String,
      reference: json['reference'] as String,
      text: json['text'] as String,
      tags: json['tags'] as String? ?? '',
      mnemonicUrl: json['mnemonic_url'] as String?,
      book: book,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }

  PassagesCompanion toCompanion(String translationId) {
    return PassagesCompanion(
      passageId: Value(passageId),
      translationId: Value(translationId),
      reference: Value(reference),
      passageText: Value(text),
      tags: Value(tags),
      mnemonicUrl: Value(mnemonicUrl),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: Value(startVerse),
      endVerse: Value(endVerse),
    );
  }
}

class TranslationSeedData {
  final String translationId;
  final String translationName;
  final List<PassageSeedData> passages;

  const TranslationSeedData({
    required this.translationId,
    required this.translationName,
    required this.passages,
  });

  factory TranslationSeedData.fromJson(Map<String, dynamic> json) {
    return TranslationSeedData(
      translationId: json['translation_id'] as String,
      translationName: json['translation_name'] as String,
      passages: (json['passages'] as List<dynamic>)
          .map((p) => PassageSeedData.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  List<PassagesCompanion> toCompanions() {
    return passages
        .map((passage) => passage.toCompanion(translationId))
        .toList();
  }
}

class SeedDataLoader {
  static const String _esvAssetPath = 'assets/data/passages_esv.json';

  static Future<TranslationSeedData> loadESV() async {
    return _loadFromAsset(_esvAssetPath);
  }

  static Future<TranslationSeedData> _loadFromAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return TranslationSeedData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load seed data from $assetPath: $e');
    }
  }

  static Future<List<PassagesCompanion>> loadESVCompanions() async {
    final seedData = await loadESV();
    return seedData.toCompanions();
  }
}
