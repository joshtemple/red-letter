import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';

class ReflectionScreen extends StatefulWidget {
  final PracticeState state;
  final ValueChanged<String> onContinue;

  const ReflectionScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  late TextEditingController _controller;
  bool _canContinue = false;

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

  void _updateState(String text) {
    setState(() {
      _canContinue = text.trim().length >= 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedLetterColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Reflection', style: RedLetterTypography.modeTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
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
                      PassageText(
                        passage: widget.state.currentPassage,
                        textAlign: TextAlign.start,
                        showReference: true,
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
                          hintText: 'Type your reflection here...',
                          onChanged: _updateState,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canContinue
                        ? () => widget.onContinue(_controller.text)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RedLetterColors.accent,
                      disabledBackgroundColor: RedLetterColors.accent
                          .withOpacity(0.3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: RedLetterTypography.modeTitle.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
