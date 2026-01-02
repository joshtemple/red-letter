import 'package:flutter/material.dart';
import 'package:red_letter/models/practice_state.dart';
import 'package:red_letter/models/word_occlusion.dart';
import 'package:red_letter/theme/colors.dart';
import 'package:red_letter/theme/typography.dart';
import 'package:red_letter/widgets/practice_footer.dart';

class ScaffoldingScreen extends StatefulWidget {
  final PracticeState state;
  final VoidCallback onContinue;
  final VoidCallback onReset;
  final WordOcclusion? occlusion; // Optional for testing

  const ScaffoldingScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onReset,
    this.occlusion,
  });

  @override
  State<ScaffoldingScreen> createState() => _ScaffoldingScreenState();
}

class _ScaffoldingScreenState extends State<ScaffoldingScreen>
    with TickerProviderStateMixin {
  late WordOcclusion _occlusion;
  late Set<int> _originallyHiddenIndices;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _occlusion =
        widget.occlusion ??
        WordOcclusion.generate(passage: widget.state.currentPassage);
    _originallyHiddenIndices = Set<int>.from(_occlusion.hiddenIndices);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isInputValid {
    final input = _inputController.text;
    if (input.isEmpty) return true;
    final targetIndex = _occlusion.firstHiddenIndex;
    if (targetIndex == null) return true;
    final targetWord = widget.state.currentPassage.words[targetIndex];
    return targetWord.toLowerCase().startsWith(input.toLowerCase());
  }

  void _handleInputChange(String input) {
    if (input.isEmpty) {
      setState(() {});
      return;
    }

    final targetIndex = _occlusion.firstHiddenIndex;
    if (targetIndex != null) {
      if (_occlusion.checkWord(targetIndex, input)) {
        // Match found!
        final nextOcclusion = _occlusion.revealIndices({targetIndex});
        setState(() {
          _occlusion = nextOcclusion;
          _inputController.clear();
        });

        // Auto-advance if complete
        if (nextOcclusion.visibleRatio >= 1.0) {
          widget.onContinue();
        }
      } else {
        // Just update state to show typing (valid or invalid)
        setState(() {});
      }
    }
  }

  bool get _isComplete {
    return _occlusion.visibleRatio >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the active word index for inline rendering
    final activeIndex = _occlusion.firstHiddenIndex;

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
        child: GestureDetector(
          onTap: () {
            // Tapping anywhere focuses the hidden input to ensure keyboard is up
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 72),
                        // Hidden input field to capture typing
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: TextField(
                            controller: _inputController,
                            focusNode: _focusNode,
                            autofocus: true,
                            onChanged: _handleInputChange,
                            autocorrect: false,
                            enableSuggestions: false,
                            // Hide the cursor and text
                            showCursor: false,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            style: const TextStyle(color: Colors.transparent),
                          ),
                        ),
                        _buildInlinePassage(activeIndex),
                        const SizedBox(height: 32),
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
      ),
    );
  }

  Widget _buildInlinePassage(int? activeIndex) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final words = widget.state.currentPassage.words;
        final spans = <InlineSpan>[];

        for (int i = 0; i < words.length; i++) {
          final isHidden = _occlusion.isWordHidden(i);
          final isLast = i == words.length - 1;

          if (isHidden) {
            final isIndexActive = i == activeIndex;
            final targetWord = words[i];

            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Reserve EXACT space of the target word
                    Text(
                      targetWord,
                      style: RedLetterTypography.passageBody.copyWith(
                        color: Colors.transparent,
                      ),
                    ),
                    // Drawn line at the bottom
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2.0,
                        decoration: BoxDecoration(
                          color: isIndexActive
                              ? (_isInputValid
                                    ? RedLetterColors.accent.withOpacity(
                                        _pulseAnimation.value,
                                      )
                                    : RedLetterColors.error)
                              : RedLetterColors.divider.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Currently typed text for active word
                    if (isIndexActive)
                      Text(
                        _inputController.text,
                        style: RedLetterTypography.passageBody.copyWith(
                          color: _isInputValid
                              ? RedLetterColors.accent
                              : RedLetterColors.error,
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else {
            // Visible (revealed or originally visible)
            final wasHidden = _originallyHiddenIndices.contains(i);
            spans.add(
              TextSpan(
                text: words[i],
                style: RedLetterTypography.passageBody.copyWith(
                  color: wasHidden ? RedLetterColors.correct : null,
                ),
              ),
            );
          }

          // Add space if not last
          if (!isLast) {
            spans.add(const TextSpan(text: ' '));
          }
        }

        return RichText(
          key: const Key('passage_text'),
          textAlign: TextAlign.center,
          text: TextSpan(
            style: RedLetterTypography.passageBody, // Default style
            children: spans,
          ),
        );
      },
    );
  }
}
