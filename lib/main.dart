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
import 'package:red_letter/screens/passage_list_screen.dart';

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
      // Set PassageListScreen as the home screen
      home: PassageListScreen(repository: repository),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RedLetterDemo extends StatefulWidget {
  final PassageRepository repository;
  final Passage? initialPassage;
  final PracticeMode? initialMode;

  const RedLetterDemo({
    super.key,
    required this.repository,
    this.initialPassage,
    this.initialMode,
  });

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
      Passage domainPassage;

      if (widget.initialPassage != null) {
        domainPassage = widget.initialPassage!;
      } else {
        // Fallback for direct testing or dev:
        // Try to load a default if none passed (e.g. for e2e test if we revert to demo)
        const demoPassageId = 'mat-5-44';
        var pwp = await widget.repository.getPassageWithProgress(demoPassageId);

        if (pwp == null) throw Exception('Default passage not found');

        domainPassage = Passage.fromText(
          id: pwp.passageId,
          text: pwp.passage.passageText,
          reference: pwp.passage.reference,
        );
      }

      // Allow override from environment or widget param, defaulting to Impression
      PracticeMode startMode = widget.initialMode ?? PracticeMode.impression;

      const envMode = String.fromEnvironment('START_MODE');
      if (envMode.isNotEmpty) {
        startMode = PracticeMode.values.firstWhere(
          (m) => m.name.toLowerCase() == envMode.toLowerCase(),
          orElse: () => startMode,
        );
      }

      if (mounted) {
        setState(() {
          _controller = PracticeController(
            domainPassage,
            repository: widget.repository,
            initialMode: startMode,
          );
          _isLoading = false;
        });
      }

      if (kDebugMode && envMode.isNotEmpty) {
        debugPrint('Red Letter: Starting in mode: ${startMode.name}');
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
