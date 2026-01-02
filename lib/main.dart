import 'package:flutter/material.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/impression_screen.dart';
import 'package:red_letter/screens/semantic_screen.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';

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
  late PracticeState _state;

  @override
  void initState() {
    super.initState();

    // Demo passage - Matthew 5:44
    final passage = Passage.fromText(
      id: 'mat-5-44',
      text: 'Love your enemies and pray for those who persecute you',
      reference: 'Matthew 5:44',
    );

    _state = PracticeState.initial(passage);
  }

  void _handleContinue([String? input]) {
    setState(() {
      if (input != null) {
        debugPrint('User Input in ${_state.currentMode}: $input');
      }
      _state = _state.advanceMode();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Advanced to ${_state.currentMode.displayName} mode'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _resetDemo() {
    setState(() {
      _state = _state.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    switch (_state.currentMode) {
      case PracticeMode.impression:
        currentScreen = ImpressionScreen(
          state: _state,
          onContinue: () => _handleContinue(),
        );
        break;
      case PracticeMode.reflection:
        currentScreen = SemanticScreen(
          state: _state,
          onContinue: (text) => _handleContinue(text),
        );
        break;
      default:
        // Placeholder for other modes
        currentScreen = Scaffold(
          backgroundColor: RedLetterColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_state.currentMode.displayName} Mode',
                  textAlign: TextAlign.center,
                  style: RedLetterTypography.modeTitle,
                ),
                const SizedBox(height: 16),
                const Text('(Coming Soon)'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
             onPressed: () => _handleContinue(),
             backgroundColor: RedLetterColors.accent,
             child: const Icon(Icons.arrow_forward),
          ),
        );
    }

    return Stack(
      children: [
        currentScreen,
        // Debug overlay showing current mode
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Mode: ${_state.currentMode.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none, 
                  ),
                ),
                Text(
                  'Completed: ${_state.completedModes.length}/5',
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
  }
}
