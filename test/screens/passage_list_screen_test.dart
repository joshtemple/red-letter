import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/database/user_progress_dao.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/screens/passage_list_screen.dart';

import 'package:red_letter/screens/session_screen.dart';

// Mock Repository
// Mock UserProgressDAO
class MockUserProgressDAO extends Fake implements UserProgressDAO {
  @override
  Future<List<UserProgress>> getReviewQueue({int? limit}) async {
    return [];
  }

  @override
  Future<List<UserProgress>> getPotentialNewCards({int? limit}) async {
    return [];
  }
}

class MockPassageRepository extends Fake implements PassageRepository {
  final StreamController<List<PassageWithProgress>> _streamController =
      StreamController<List<PassageWithProgress>>.broadcast();

  final _mockProgressDAO = MockUserProgressDAO();

  @override
  UserProgressDAO get progressDAO => _mockProgressDAO;

  // Expose function to emit data for testing
  void emit(List<PassageWithProgress> data) {
    _streamController.add(data);
  }

  @override
  Stream<List<PassageWithProgress>> watchAllPassagesWithProgress() {
    return _streamController.stream;
  }

  @override
  Future<int> updateMasteryLevel(String passageId, int level) async {
    return 1; // Return row id
  }

  @override
  Future<PassageWithProgress?> getPassageWithProgress(String passageId) async {
    // Return a dummy passage for the Practice Screen usage
    return PassageWithProgress(
      passage: Passage(
        passageId: passageId,
        reference: 'Test Ref',
        passageText: 'Test Text',
        translationId: 'esv',
        tags: '',
        mnemonicUrl: null,
        book: 'Matthew',
        chapter: 5,
        startVerse: 1,
        endVerse: 1,
      ),
      progress: UserProgress(
        id: 1,
        passageId: passageId,
        masteryLevel: 0,
        stability: 0.0,
        difficulty: 5.0,
        step: null,
        state: 0, // Learning state
        semanticReflection: null,
        lastReviewed: null,
        nextReview: null,
        lastSync: null,
      ),
    );
  }
}

void main() {
  group('PassageListScreen', () {
    late MockPassageRepository repository;

    setUp(() {
      repository = MockPassageRepository();
    });

    tearDown(() {
      // Stream controller is closed by GC
    });

    testWidgets('Renders items from stream', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PassageListScreen(repository: repository)),
      );

      // Emit data
      repository.emit([
        PassageWithProgress(
          passage: const Passage(
            passageId: '1',
            reference: 'Matt 5:44',
            passageText: 'Love your enemies',
            translationId: 'esv',
            tags: '',
            mnemonicUrl: null,
            book: 'Matthew',
            chapter: 5,
            startVerse: 44,
            endVerse: 44,
          ),
          progress: null,
        ),
        PassageWithProgress(
          passage: const Passage(
            passageId: '2',
            reference: 'John 11:35',
            passageText: 'Jesus wept',
            translationId: 'esv',
            tags: '',
            mnemonicUrl: null,
            book: 'John',
            chapter: 11,
            startVerse: 35,
            endVerse: 35,
          ),
          progress: const UserProgress(
            id: 2,
            passageId: '2',
            masteryLevel: 5,
            stability: 10.0,
            difficulty: 4.0,
            step: null,
            state: 1, // Review state
            semanticReflection: null,
            lastReviewed: null,
            nextReview: null,
            lastSync: null,
          ),
        ),
      ]);

      await tester.pump(); // Process stream
      await tester.pumpAndSettle(); // Settle UI

      // Verify items are present
      expect(find.text('Matt 5:44'), findsOneWidget);
      expect(find.text('John 11:35'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // Default mastery
      expect(find.text('5'), findsOneWidget); // Mastered
    });

    testWidgets('"Memorize" button starts practice session', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PassageListScreen(repository: repository)),
      );

      repository.emit([
        PassageWithProgress(
          passage: const Passage(
            passageId: '1',
            reference: 'Ref',
            passageText: 'Text',
            translationId: 'esv',
            tags: '',
            mnemonicUrl: null,
            book: 'Test',
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
          ),
          progress: const UserProgress(
            id: 1,
            passageId: '1',
            masteryLevel: 1,
            stability: 0.0,
            difficulty: 5.0,
            step: null,
            state: 0, // Learning state
            semanticReflection: null,
            lastReviewed: null,
            nextReview: null,
            lastSync: null,
          ), // Level 1 -> Reflection
        ),
      ]);

      await tester.pumpAndSettle();

      // Find FAB
      final fab = find.widgetWithText(FloatingActionButton, 'START SESSION');
      expect(fab, findsOneWidget);

      // Tap it
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Should navigate to SessionScreen
      expect(find.byType(SessionScreen), findsOneWidget);
    });
  });
}
