import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';

void main() {
  group('Persistence & Offline Capabilities', () {
    test('Data persists across repository interactions', () async {
      // Simulate persistence by using an in-memory database.
      // In a real app, this would be a file-based SQLite database.
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = PassageRepository.fromDatabase(database);

      const passageId = 'mat-5-44';

      // 1. Seed initial data
      await repository.insertPassage(
        PassagesCompanion(
          passageId: const Value(passageId),
          reference: const Value('Matthew 5:44'),
          passageText: const Value('Text'),
          translationId: const Value('esv'),
        ),
      );

      // 2. Simulate User completing Impression Mode (creates progress)
      await repository.createProgress(passageId);
      var progress = await repository.getProgress(passageId);
      expect(progress, isNotNull);
      expect(progress!.masteryLevel, 0);

      // 3. Simulate User completing Prompted Mode (updates mastery)
      await repository.updateMasteryLevel(passageId, 1);

      // 4. Simulate User adding Reflection
      await repository.updateSemanticReflection(passageId, 'My reflection');

      // 5. Verify data reliability
      final freshFetch = await repository.getProgress(passageId);
      expect(freshFetch!.masteryLevel, 1);
      expect(freshFetch.semanticReflection, 'My reflection');

      await database.close();
    });

    test('Offline-first: Operations work without network', () async {
      // Verify that repository operations function correctly purely locally.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = PassageRepository.fromDatabase(db);

      // Attempt to read/write - should succeed without any network stack
      await repository.insertPassage(
        PassagesCompanion(
          passageId: const Value('offline-test'),
          reference: const Value('Ref'),
          passageText: const Value('Text'),
          translationId: const Value('esv'),
        ),
      );

      final result = await repository.getPassage('offline-test');
      expect(result, isNotNull);

      await db.close();
    });
  });
}
