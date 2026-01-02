import 'package:flutter/material.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/theme/colors.dart';

import 'package:red_letter/widgets/passage_list_item.dart';
import 'package:red_letter/controllers/practice_session_controller.dart';
import 'package:red_letter/main.dart'; // For navigation to RedLetterDemo (Practice Screen)
import 'package:red_letter/models/passage.dart'; // Domain model

class PassageListScreen extends StatelessWidget {
  final PassageRepository repository;
  final PracticeSessionController _sessionController =
      PracticeSessionController();

  PassageListScreen({super.key, required this.repository});

  void _startPractice(BuildContext context, PassageWithProgress pwp) {
    // Determine mode based on mastery level
    final mode = _sessionController.getModeForLevel(pwp.masteryLevel);

    // Convert Drift Passage to Domain Passage
    final domainPassage = Passage.fromText(
      id: pwp.passageId,
      text: pwp.passage.passageText,
      reference: pwp.passage.reference,
    );

    // Navigate to Practice Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RedLetterDemo(
          repository: repository,
          initialPassage: domainPassage,
          initialMode: mode,
        ),
      ),
    );
  }

  void _handleMemorize(
    BuildContext context,
    List<PassageWithProgress> passages,
  ) {
    final selected = _sessionController.selectRandomPassage(passages);
    if (selected != null) {
      _startPractice(context, selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No passages available to memorize!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Passages',
          style: TextStyle(
            color: RedLetterColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<PassageWithProgress>>(
        stream: repository.watchAllPassagesWithProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final passages = snapshot.data ?? [];

          if (passages.isEmpty) {
            return const Center(
              child: Text(
                'No passages found.\nWait for seeding...',
                textAlign: TextAlign.center,
                style: TextStyle(color: RedLetterColors.secondaryText),
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                itemCount: passages.length,
                itemBuilder: (context, index) {
                  final pwp = passages[index];
                  return PassageListItem(
                    passageWithProgress: pwp,
                    onTap: () => _startPractice(context, pwp),
                  );
                },
              ),

              // Floating Action Button for "Memorize"
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    onPressed: () => _handleMemorize(context, passages),
                    backgroundColor: RedLetterColors.accent,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'MEMORIZE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
