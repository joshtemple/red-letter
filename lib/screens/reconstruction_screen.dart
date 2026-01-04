import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/passage_validator.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/practice_footer.dart';

class ReconstructionScreen extends StatefulWidget {
  final PracticeState state;
  final Function(String) onContinue;
  final VoidCallback onReset;

  const ReconstructionScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
  });

  @override
  State<ReconstructionScreen> createState() => _ReconstructionScreenState();
}

class _ReconstructionScreenState extends State<ReconstructionScreen> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _userInput = '';

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

  void _handleInputChange(String input) {
    setState(() {
      _userInput = input;
    });
  }

  bool get _isComplete {
    return PassageValidator.isStrictMatch(
      widget.state.currentPassage.text,
      _userInput,
    );
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        widget.state.currentPassage.reference,
                        style: RedLetterTypography.passageReference,
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _handleInputChange,
                        maxLines: null,
                        style: RedLetterTypography.userInputText,
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          hintText: 'Type the passage...',
                          hintStyle: RedLetterTypography.hintText,
                          border: InputBorder.none,
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
                onContinue: () => widget.onContinue(_userInput),
                continueEnabled: _isComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
