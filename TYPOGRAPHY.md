## Typography Rendering Performance

This document outlines the typography system and performance optimizations for Red Letter.

## Typography System

Red Letter uses a carefully curated typography system designed for premium text-first experience with zero-lag performance.

### Font Stack

**Serif (Passage Text):**
- Primary: Georgia (built-in on iOS/Android)
- Fallback: System serif font
- Usage: Scripture passages, user input
- Characteristics: High readability, classical feel, excellent for long-form reading

**Sans-Serif (UI Text):**
- Primary: SF Pro Text (iOS), Roboto (Android)
- Fallback: System sans-serif font
- Usage: References, mode titles, prompts, UI elements
- Characteristics: Clean, modern, excellent for metadata

**Monospace (Optional Input):**
- Primary: SF Mono (iOS), Roboto Mono (Android)
- Usage: Alternative input mode for precise character alignment
- Characteristics: Fixed-width, excellent for typing validation

### Text Styles

Defined in `lib/theme/typography.dart`:

- **passageBody**: 22pt serif, 1.6 line-height, subtle letter-spacing
- **passageReference**: 14pt sans-serif, medium weight
- **userInputText**: 22pt serif, matches passageBody for consistency
- **userInputTextMonospace**: 20pt monospace, for character-precise input
- **modeTitle**: 16pt sans-serif, semi-bold, uppercase tracking
- **promptText**: 16pt sans-serif, for semantic mode prompts
- **hintText**: 14pt sans-serif, italic, muted color

### Color Palette

Defined in `lib/theme/colors.dart`:

- **Text Colors**: High-contrast black (#1A1A1A) on warm white background (#FFFBF5)
- **Accent**: Golden tones for emphasis (#B8860B, #D4AF37)
- **Feedback**: Semantic colors for correct/error states

## Performance Optimizations

### 1. RepaintBoundary Usage

Wrap static text with `RepaintBoundary` to isolate rendering:

```dart
RepaintBoundary(
  child: Text(
    passage.text,
    style: RedLetterTypography.passageBody,
  ),
)
```

This prevents unnecessary repaints when other parts of the UI change.

### 2. Impeller Rendering

Impeller (enabled by default in Flutter 3.38.5 on iOS) provides:
- Zero shader compilation jank
- Predictable frame timing
- Premium text anti-aliasing

Verify Impeller is active: `flutter run --enable-impeller`

### 3. Text Measurement Caching

Flutter automatically caches text measurement, but avoid:
- Changing TextStyle properties on every frame
- Dynamic font size calculations in build()
- Unnecessary text wrapping/truncation

### 4. Input Field Performance

For real-time typing validation (<16ms requirement):

```dart
TextField(
  onChanged: (value) {
    // Validate on isolate for long passages
    compute(validateInput, value);
  },
  style: RedLetterTypography.userInputText,
  decoration: InputDecoration(
    border: InputBorder.none, // Reduce decoration overhead
  ),
)
```

### 5. Long Passage Handling

For passages with 200+ words:

- Use `ListView.builder` for scrollable content
- Wrap each paragraph in `RepaintBoundary`
- Consider text chunking for extremely long passages
- Profile with Flutter DevTools to ensure 60fps

### 6. Platform-Specific Optimizations

**iOS:**
- Impeller enabled by default
- SF Pro Text has native optimizations
- Use CupertinoScrollbar for native feel

**Android:**
- Test with and without Impeller
- Roboto has native optimizations
- Consider MaterialScrollbar

## Testing

### Performance Benchmarks

Target: **60fps** (16.67ms per frame)

Test scenarios:
1. Static passage display: <2ms render time
2. User typing validation: <8ms per keystroke
3. Mode transitions: <100ms total animation
4. Long passage scroll: Consistent 60fps

### Validation Steps

1. Run with profile mode: `flutter run --profile --enable-impeller`
2. Open Flutter DevTools Performance tab
3. Record timeline while:
   - Displaying passages of varying lengths
   - Typing at normal speed (40-60 WPM)
   - Scrolling through long passages
   - Transitioning between modes
4. Verify:
   - No frame drops (all frames <16.67ms)
   - No shader compilation jank
   - Text rendering happens in <5ms
   - Input latency <10ms

### Visual Quality

Test typography rendering on:
- iOS Simulator (retina displays)
- Physical iPhone (various models)
- Android Emulator (various DPI)
- Physical Android devices

Verify:
- Text is crisp and readable
- Letter-spacing is consistent
- Line-height provides comfortable reading
- Colors have sufficient contrast
- Anti-aliasing is smooth

## Best Practices

1. **Always use const** for TextStyle definitions
2. **Wrap static text** in RepaintBoundary
3. **Avoid dynamic styles** in build()
4. **Profile regularly** with DevTools
5. **Test on real devices** for accurate performance metrics
6. **Measure input latency** to ensure <16ms response time

## References

- [Flutter Impeller](https://docs.flutter.dev/perf/impeller)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Text Rendering Performance](https://docs.flutter.dev/perf/rendering-performance)
