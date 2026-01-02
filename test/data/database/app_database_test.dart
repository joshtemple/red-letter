import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase Initialization', () {
    test('should create database with correct schema version', () {
      expect(database.schemaVersion, equals(1));
    });

    test('should create all tables successfully', () async {
      // Trigger database creation by running a simple query
      final passages = await database.select(database.passages).get();
      expect(passages, isEmpty);

      final userProgress = await database.select(database.userProgressTable).get();
      expect(userProgress, isEmpty);
    });

    test('should enforce foreign key constraints', () async {
      // Try to insert user progress without corresponding passage (should fail)
      await expectLater(
        database.into(database.userProgressTable).insert(
          UserProgressTableCompanion.insert(
            passageId: 'non-existent-id',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should support passage insertion', () async {
      // Insert a test passage
      await database.into(database.passages).insert(
        PassagesCompanion.insert(
          passageId: 'test-1',
          translationId: 'niv',
          reference: 'Test 1:1',
          passageText: 'Test passage text',
        ),
      );

      final passages = await database.select(database.passages).get();
      expect(passages, hasLength(1));
      expect(passages.first.passageId, equals('test-1'));
      expect(passages.first.reference, equals('Test 1:1'));
    });

    test('should support user progress insertion with valid foreign key', () async {
      // First insert a passage
      await database.into(database.passages).insert(
        PassagesCompanion.insert(
          passageId: 'test-2',
          translationId: 'niv',
          reference: 'Test 2:1',
          passageText: 'Test passage text 2',
        ),
      );

      // Then insert user progress
      await database.into(database.userProgressTable).insert(
        UserProgressTableCompanion.insert(
          passageId: 'test-2',
        ),
      );

      final progress = await database.select(database.userProgressTable).get();
      expect(progress, hasLength(1));
      expect(progress.first.passageId, equals('test-2'));
      expect(progress.first.masteryLevel, equals(0)); // Default value
    });

    test('should cascade delete user progress when passage is deleted', () async {
      // Insert passage and user progress
      await database.into(database.passages).insert(
        PassagesCompanion.insert(
          passageId: 'test-3',
          translationId: 'niv',
          reference: 'Test 3:1',
          passageText: 'Test passage text 3',
        ),
      );

      await database.into(database.userProgressTable).insert(
        UserProgressTableCompanion.insert(
          passageId: 'test-3',
        ),
      );

      // Delete the passage
      await (database.delete(database.passages)
            ..where((t) => t.passageId.equals('test-3')))
          .go();

      // User progress should also be deleted
      final progress = await database.select(database.userProgressTable).get();
      expect(progress, isEmpty);
    });
  });
}
