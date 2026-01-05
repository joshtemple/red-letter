import 'package:flutter/material.dart';
import 'package:red_letter/data/models/passage_with_progress.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/screens/developer_options_screen.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/widgets/passage_list_item.dart';
import 'package:red_letter/screens/session_screen.dart';

class PassageListScreen extends StatelessWidget {
  final PassageRepository repository;

  const PassageListScreen({super.key, required this.repository});

  void _handleMemorize(BuildContext context) {
    // Navigate to the Session Orchestrator
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionScreen(repository: repository),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bug_report,
              color: RedLetterColors.secondaryText,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      DeveloperOptionsScreen(repository: repository),
                ),
              );
            },
          ),
        ],
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
                    key: ValueKey(pwp.passageId),
                    passageWithProgress: pwp,
                    onTap: () {
                      // Placeholder for detail view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use "Start Session" to practice'),
                        ),
                      );
                    },
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
                    onPressed: () => _handleMemorize(context),
                    backgroundColor: RedLetterColors.accent,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'START SESSION',
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
