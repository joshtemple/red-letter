import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';
import 'package:red_letter/widgets/practice_footer.dart';

class ReflectionScreen extends StatefulWidget {
  final PracticeState state;
  final ValueChanged<String> onContinue;
  final VoidCallback onReset;

  const ReflectionScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
  });

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateState(String text) {
    setState(() {
      // Character minimum disabled for testing
      _canContinue = text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        widget.state.currentPassage.reference,
                        style: RedLetterTypography.passageReference,
                      ),
                      const SizedBox(height: 24),
                      PassageText(
                        passage: widget.state.currentPassage,
                        textAlign: TextAlign.start,
                        showReference: false, // Moved to AppBar
                        enableShadow: false,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'What does this command mean to you?',
                        style: RedLetterTypography.promptText,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RedLetterColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RedLetterColors.divider),
                        ),
                        child: PassageInput(
                          controller: _controller,
                          focusNode: _focusNode,
                          hintText: 'Type your reflection here...',
                          onChanged: _updateState,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              PracticeFooter(
                onReset: widget.onReset,
                onContinue: () => widget.onContinue(_controller.text),
                continueEnabled: _canContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
