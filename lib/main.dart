import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_letter/data/database/app_database.dart' hide Passage;
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/models/passage.dart';
import 'package:red_letter/models/practice_mode.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/screens/impression_screen.dart';
import 'package:red_letter/screens/reflection_screen.dart';
import 'package:red_letter/screens/scaffolding_screen.dart';
import 'package:red_letter/screens/prompted_screen.dart';
import 'package:red_letter/screens/reconstruction_screen.dart';
import 'package:red_letter/controllers/practice_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and repository
  final database = AppDatabase();
  final repository = PassageRepository.fromDatabase(database);

  runApp(RedLetterApp(repository: repository));
}

class RedLetterApp extends StatelessWidget {
  final PassageRepository repository;

  const RedLetterApp({super.key, required this.repository});

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
      home: RedLetterDemo(repository: repository),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RedLetterDemo extends StatefulWidget {
  final PassageRepository repository;

  const RedLetterDemo({super.key, required this.repository});

  @override
  State<RedLetterDemo> createState() => _RedLetterDemoState();
}

class _RedLetterDemoState extends State<RedLetterDemo> {
  PracticeController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPassage();
  }

  Future<void> _loadPassage() async {
    try {
      // Demo passage - Matthew 5:44
      const demoPassageId = 'mat-5-44';

      // Try to get passage with progress from DB
      var passageWithProgress = await widget.repository.getPassageWithProgress(
        demoPassageId,
      );

      // If not found, it might be that seeding hasn't finished or failed (though migration should handle it).
      // Or we can try to wait/retry? For now, we assume seeding works.
      if (passageWithProgress == null) {
        // Fallback: Check if we can get just the passage (maybe no progress yet, but getPassageWithProgress handles that)
        // If null, it means the passage ID doesn't exist in DB.

        // FOR DEV: If database is empty (e.g. running tests with empty db), we might need to wait or it's a critical error.
        // Assuming database seeder runs on creation.

        throw Exception('Passage not found: $demoPassageId');
      }

      // Convert Drift passage to Domain Passage
      final domainPassage = Passage.fromText(
        id: passageWithProgress.passageId,
        text: passageWithProgress.passage.passageText,
        reference: passageWithProgress.passage.reference,
      );

      // Allows starting at a specific mode for development
      // Usage: flutter run --dart-define=START_MODE=scaffolding
      const startModeName = String.fromEnvironment('START_MODE');
      final initialMode = PracticeMode.values.firstWhere(
        (m) => m.name.toLowerCase() == startModeName.toLowerCase(),
        orElse: () => PracticeMode.impression,
      );

      if (mounted) {
        setState(() {
          _controller = PracticeController(
            domainPassage,
            repository: widget.repository,
            initialMode: initialMode,
          );
          _isLoading = false;
        });
      }

      if (kDebugMode && startModeName.isNotEmpty) {
        debugPrint('Red Letter: Starting in mode: ${initialMode.name}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading passage: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleContinue([String? input]) {
    _controller?.advance(input);
  }

  void _resetDemo() {
    _controller?.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: RedLetterColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: RedLetterColors.background,
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<PracticeState>(
      valueListenable: _controller!,
      builder: (context, state, child) {
        Widget currentScreen;

        switch (state.currentMode) {
          case PracticeMode.impression:
            currentScreen = ImpressionScreen(
              state: state,
              onContinue: () => _handleContinue(),
              onReset: _resetDemo,
            );
            break;
          case PracticeMode.reflection:
            currentScreen = ReflectionScreen(
              state: state,
              onContinue: (text) => _handleContinue(text),
              onReset: _resetDemo,
            );
            break;
          case PracticeMode.scaffolding:
            currentScreen = ScaffoldingScreen(
              state: state,
              onContinue: () => _handleContinue(),
              onReset: _resetDemo,
            );
            break;
          case PracticeMode.prompted:
            currentScreen = PromptedScreen(
              state: state,
              onContinue: () => _handleContinue(),
              onReset: _resetDemo,
            );
            break;
          case PracticeMode.reconstruction:
            currentScreen = ReconstructionScreen(
              state: state,
              onContinue: () => _handleContinue(),
              onReset: _resetDemo,
            );
            break;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: KeyedSubtree(
            key: ValueKey(state.currentMode),
            child: currentScreen,
          ),
        );
      },
    );
  }
}
