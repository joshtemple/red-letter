import 'package:flutter/material.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:drift/drift.dart' as drift;

/// Developer screen to manually manipulate passage states for testing.
class DeveloperOptionsScreen extends StatefulWidget {
  final PassageRepository repository;

  const DeveloperOptionsScreen({super.key, required this.repository});

  @override
  State<DeveloperOptionsScreen> createState() => _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen> {
  // Helper to update progress directly
  Future<void> _updateProgress(
    String passageId, {
    required int state,
    required double stability,
    required double difficulty,
    required int masteryLevel,
    required DateTime? nextReview,
  }) async {
    // We access the DAO directly via the repo's provider reference if possible,
    // or we can use the createProgress/upsertProgress methods exposed by the repo.
    // Since the repo might not expose raw upsert for arbitrary values,
    // we might need to rely on the DAO being accessible or add a method to the repo.
    // For now, assuming we can get the DAO or use the database directly if we had a reference.
    //
    // SHORTCUT: We will use the repository's `database` getter if it exists, or
    // we'll assume we can pass the database in.
    // Actually, looking at the code, PassageRepository usually holds the db.

    // Let's try to get the DAO from the repo if exposed, or just use a workaround.
    // If Repository doesn't expose it, we might need to add a "debugUpdate" method to it.
    // Or we can just create a temporary DAO here if we have the database.
    //
    // IMPORTANT: Check PassageRepository definition in a moment.
    // For this preview, I'll assume we can add a method to the repository or
    // use a global/service locator if available.

    // Let's assume we add a debug method to PassageRepository for now.
    await widget.repository.debugUpdateProgress(
      passageId,
      UserProgressTableCompanion(
        passageId: drift.Value(passageId),
        state: drift.Value(state),
        stability: drift.Value(stability),
        difficulty: drift.Value(difficulty),
        masteryLevel: drift.Value(masteryLevel),
        nextReview: drift.Value(nextReview),
        lastReviewed: drift.Value(DateTime.now()),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Updated $passageId')));
    }
  }

  Future<void> _resetProgress(String passageId) async {
    await widget.repository.deleteProgress(passageId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset $passageId')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        title: const Text('Developer Options'),
        backgroundColor: RedLetterColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset All Progress?'),
                  content: const Text(
                    'This will delete ALL practice history and reset mastery for all passages. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await widget.repository.deleteAllProgress();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All progress deleted')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PassageWithProgress>>(
        stream: widget.repository.watchAllPassagesWithProgress(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final passages = snapshot.data!;
          return ListView.builder(
            itemCount: passages.length,
            itemBuilder: (context, index) {
              final item = passages[index];
              final p = item.progress; // nullable

              return ExpansionTile(
                title: Text(
                  item.passage.reference,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Mastery: ${p?.masteryLevel ?? 0} | FSRS State: ${p?.state ?? "New"}',
                  style: const TextStyle(color: Colors.grey),
                ),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _resetProgress(item.passage.passageId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateProgress(
                          item.passage.passageId,
                          state: 1, // Review
                          stability: 2.0,
                          difficulty: 5.0,
                          masteryLevel: 1, // Acquired
                          nextReview: DateTime.now().add(
                            const Duration(minutes: 10),
                          ),
                        ),
                        child: const Text('Set: Acquired (M1)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateProgress(
                          item.passage.passageId,
                          state: 1, // Review
                          stability: 20.0,
                          difficulty: 5.0,
                          masteryLevel: 3, // Strong
                          nextReview: DateTime.now().add(
                            const Duration(days: 20),
                          ),
                        ),
                        child: const Text('Set: Strong (M3)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateProgress(
                          item.passage.passageId,
                          state: 1, // Review
                          stability: 5.0,
                          difficulty: 5.0,
                          masteryLevel: 2,
                          nextReview: DateTime.now().subtract(
                            const Duration(minutes: 1),
                          ), // Due now
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: const Text('Due Now'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
