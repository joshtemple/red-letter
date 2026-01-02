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

  const PassageSeedData({
    required this.passageId,
    required this.reference,
    required this.text,
    required this.tags,
    this.mnemonicUrl,
  });

  factory PassageSeedData.fromJson(Map<String, dynamic> json) {
    return PassageSeedData(
      passageId: json['passage_id'] as String,
      reference: json['reference'] as String,
      text: json['text'] as String,
      tags: json['tags'] as String? ?? '',
      mnemonicUrl: json['mnemonic_url'] as String?,
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
