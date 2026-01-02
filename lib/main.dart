import 'package:flutter/material.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/impression_screen.dart';
import 'package:red_letter/screens/reflection_screen.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';
import 'package:red_letter/screens/prompted_screen.dart';
import 'package:red_letter/screens/reconstruction_screen.dart';
import 'package:red_letter/controllers/practice_controller.dart';
import 'package:red_letter/theme/colors.dart';

void main() {
  runApp(const RedLetterApp());
}

class RedLetterApp extends StatelessWidget {
  const RedLetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Letter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: RedLetterColors.accent,
          background: RedLetterColors.background,
        ),
        useMaterial3: true,
      ),
      home: const RedLetterDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RedLetterDemo extends StatefulWidget {
  const RedLetterDemo({super.key});

  @override
  State<RedLetterDemo> createState() => _RedLetterDemoState();
}

class _RedLetterDemoState extends State<RedLetterDemo> {
  late PracticeController _controller;

  @override
  void initState() {
    super.initState();

    // Demo passage - Matthew 5:44
    final passage = Passage.fromText(
      id: 'mat-5-44',
      text: 'Love your enemies and pray for those who persecute you',
      reference: 'Matthew 5:44',
    );

    _controller = PracticeController(passage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleContinue([String? input]) {
    _controller.advance(input);
  }

  void _resetDemo() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PracticeState>(
      valueListenable: _controller,
      builder: (context, state, child) {
        Widget currentScreen;

        switch (state.currentMode) {
          case PracticeMode.impression:
            currentScreen = ImpressionScreen(
              state: state,
              onContinue: () => _handleContinue(),
            );
            break;
          case PracticeMode.reflection:
            currentScreen = ReflectionScreen(
              state: state,
              onContinue: (text) => _handleContinue(text),
            );
            break;
          case PracticeMode.scaffolding:
            currentScreen = ScaffoldingScreen(
              state: state,
              onContinue: () => _handleContinue(),
            );
            break;
          case PracticeMode.prompted:
            currentScreen = PromptedScreen(
              state: state,
              onContinue: () => _handleContinue(),
            );
            break;
          case PracticeMode.reconstruction:
            currentScreen = ReconstructionScreen(
              state: state,
              onContinue: () => _handleContinue(),
            );
            break;
        }

        return Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: KeyedSubtree(
                key: ValueKey(state.currentMode),
                child: currentScreen,
              ),
            ),
            // Debug overlay showing current mode
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Mode: ${state.currentMode.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      'Completed: ${state.completedModes.length}/5',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _resetDemo,
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
