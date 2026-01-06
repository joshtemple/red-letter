import 'package:flutter/material.dart';
import 'package:red_letter/models/clause_segmentation.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/passage_text.dart';
import 'package:red_letter/widgets/practice_footer.dart';

class ImpressionScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;

  const ImpressionScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<ImpressionScreen> createState() => _ImpressionScreenState();
}

class _ImpressionScreenState extends State<ImpressionScreen>
    with SingleTickerProviderStateMixin {
  late ClauseSegmentation _segmentation;
  int _revealedClauseCount = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _segmentation = ClauseSegmentation.fromPassage(widget.state.currentPassage);

    // Initialize fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Reveal first clause after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _revealedClauseCount = 1;
        });
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_revealedClauseCount < _segmentation.clauseCount) {
      setState(() {
        _revealedClauseCount++;
      });
      _fadeController.forward(from: 0.0);
    }
  }

  String _getInstructionText() {
    if (_revealedClauseCount >= _segmentation.clauseCount) {
      return 'Read this passage aloud twice';
    } else {
      return 'Tap to reveal the passage';
    }
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
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _handleTap,
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getInstructionText(),
                            style: RedLetterTypography.promptText.copyWith(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: RedLetterColors.secondaryText,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 32),
                          RevealablePassageText(
                            passage: widget.state.currentPassage,
                            segmentation: _segmentation,
                            revealedClauseCount: _revealedClauseCount,
                            fadeAnimation: _fadeAnimation,
                            textAlign: TextAlign.start,
                            enableShadow: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_revealedClauseCount >= _segmentation.clauseCount)
                PracticeFooter(onContinue: widget.onContinue),
            ],
          ),
        ),
      ),
    );
  }
}
