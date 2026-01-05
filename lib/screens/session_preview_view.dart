import 'package:flutter/material.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/theme/colors.dart';

class SessionPreviewView extends StatelessWidget {
  final List<UserProgress> cards;
  final PassageRepository repository;
  final VoidCallback onStart;

  const SessionPreviewView({
    super.key,
    required this.cards,
    required this.repository,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        title: const Text(
          "Today's Session",
          style: TextStyle(color: RedLetterColors.primaryText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final card = cards[index];
                return _PreviewCardItem(card: card, repository: repository);
              },
            ),
          ),
          _buildStartButton(context),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: RedLetterColors.surface, // Or transparent/background
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: RedLetterColors.accent,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onStart,
          child: const Text(
            'START SESSION',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCardItem extends StatelessWidget {
  final UserProgress card;
  final PassageRepository repository;

  const _PreviewCardItem({required this.card, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.getPassage(card.passageId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Placeholder while loading
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: RedLetterColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        final passage = snapshot.data!;
        final isNew = card.masteryLevel == 0;
        final isReview = card.state == 1;
        final isRelearning = card.state == 2;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: RedLetterColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  passage.reference,
                  style: const TextStyle(
                    color: RedLetterColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isNew)
                _buildBadge('NEW', Colors.green)
              else if (isRelearning)
                _buildBadge('AGAIN', Colors.orange)
              else if (isReview)
                _buildBadge('REVIEW', Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
