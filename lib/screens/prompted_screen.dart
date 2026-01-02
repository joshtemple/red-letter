import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/practice_footer.dart';

class PromptedScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final VoidCallback onReset;

  const PromptedScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
  });

  @override
  State<PromptedScreen> createState() => _PromptedScreenState();
}

class _PromptedScreenState extends State<PromptedScreen> {
  late TextEditingController _controller;
  String _userInput = '';
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleInputChange(String input) {
    final isValid = PassageValidator.isValidPrefix(
      widget.state.currentPassage.text,
      input,
    );
    setState(() {
      _userInput = input;
      _isValid = isValid;
    });
  }

  void _showHint() {
    final hint = PassageValidator.getNextHint(
      widget.state.currentPassage.text,
      _userInput,
    );

    if (hint.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hint: $hint'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _isComplete {
    return PassageValidator.isLenientMatch(
      widget.state.currentPassage.text,
      _userInput,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.state.currentPassage.reference,
          style: RedLetterTypography.passageReference,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Type the passage from memory:',
                        style: RedLetterTypography.promptText,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _controller,
                        onChanged: _handleInputChange,
                        maxLines: null,
                        style: _isValid
                            ? RedLetterTypography.userInputText
                            : RedLetterTypography.userInputText.copyWith(
                                color: RedLetterColors.error,
                              ),
                        decoration: InputDecoration(
                          hintText: 'Start typing...',
                          hintStyle: RedLetterTypography.hintText,
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.lightbulb_outline,
                              color: RedLetterColors.accent,
                            ),
                            onPressed: _showHint,
                            tooltip: 'Get a hint',
                          ),
                        ),
                        autofocus: true,
                        enableSuggestions: false,
                        autocorrect: false,
                      ),
                    ],
                  ),
                ),
              ),
              PracticeFooter(
                onReset: widget.onReset,
                onContinue: widget.onContinue,
                continueEnabled: _isComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
