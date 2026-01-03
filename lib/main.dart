import 'package:flutter/material.dart';
import 'package:red_letter/data/database/app_database.dart';
import 'package:red_letter/data/repositories/passage_repository.dart';
import 'package:red_letter/theme/colors.dart';
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
