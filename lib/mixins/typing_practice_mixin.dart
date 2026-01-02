import 'dart:async';
import 'package:flutter/material.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/word_occlusion.dart';

mixin TypingPracticeMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late TextEditingController inputController;
  late FocusNode focusNode;
  bool isProcessingError = false;

  late AnimationController pulseController;
  late Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();
    inputController = TextEditingController();
    focusNode = FocusNode();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    focusNode.dispose();
    pulseController.dispose();
    super.dispose();
  }

  bool isInputValid(WordOcclusion occlusion, Passage passage) {
    final input = inputController.text;
    if (input.isEmpty) return true;
    final targetIndex = occlusion.firstHiddenIndex;
    if (targetIndex == null) return true;
    final targetWord = passage.words[targetIndex];

    // No feedback until the full word is typed
    if (input.length < targetWord.length) return true;

    return occlusion.checkWord(targetIndex, input);
  }

  void handleInputChange({
    required String input,
    required WordOcclusion currentOcclusion,
    required Passage passage,
    required Function(WordOcclusion) onWordMatched,
    required VoidCallback onComplete,
    required VoidCallback onStateChanged,
  }) {
    if (input.isEmpty) {
      onStateChanged();
      return;
    }

    final targetIndex = currentOcclusion.firstHiddenIndex;
    if (targetIndex != null) {
      if (currentOcclusion.checkWord(targetIndex, input)) {
        // Match found!
        final nextOcclusion = currentOcclusion.revealIndices({targetIndex});
        inputController.clear();
        onWordMatched(nextOcclusion);

        // Auto-advance if complete
        if (nextOcclusion.visibleRatio >= 1.0) {
          onComplete();
        }
      } else {
        // Validation logic for auto-clearing
        final targetWord = passage.words[targetIndex];

        bool shouldClear = false;
        if (input.length > targetWord.length) {
          shouldClear = true;
        } else if (input.length == targetWord.length) {
          final prefix = input.substring(0, input.length - 1);
          final isPrefixCorrect = targetWord.toLowerCase().startsWith(
            prefix.toLowerCase(),
          );
          if (!isPrefixCorrect) {
            shouldClear = true;
          }
        }

        if (shouldClear) {
          isProcessingError = true;
          onStateChanged();
          // Short delay to show the error state (red)
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              inputController.clear();
              isProcessingError = false;
              onStateChanged();
            }
          });
        } else {
          onStateChanged();
        }
      }
    }
  }
}
