# Impeller Rendering Configuration

## Overview

Red Letter uses Flutter's Impeller rendering engine for jank-free animations and premium typography. Impeller is Flutter's next-generation rendering engine that precompiles shaders to avoid runtime shader compilation jank.

## Status in Flutter 3.38.5

**Impeller is enabled by default on iOS** as of Flutter 3.10+. However, we explicitly enable it to ensure consistency and future compatibility.

## Running with Impeller

### Command Line

**Debug mode:**
```bash
flutter run --enable-impeller
```

**Profile mode** (for performance testing):
```bash
flutter run --profile --enable-impeller
```

**Release mode:**
```bash
flutter run --release --enable-impeller
```

### Specific Device

```bash
flutter run --enable-impeller -d <device-id>
```

To list available devices:
```bash
flutter devices
```

## Verifying Impeller is Active

### Method 1: Console Logs

When running the app, check the console output for:
```
Impeller rendering backend enabled
```

Or look for the absence of:
```
Using Skia rendering backend
```

### Method 2: Flutter Inspector

1. Run app in debug mode with DevTools:
   ```bash
   flutter run --enable-impeller --observatory-port=9200
   ```

2. Open DevTools and check the Performance tab for Impeller-specific metrics

### Method 3: Runtime Check (Code)

Add this debug print to verify at runtime:

```dart
import 'dart:ui' as ui;

void main() {
  // Check if Impeller is enabled
  debugPrint('Impeller enabled: ${ui.ImpellerEnabled}');
  runApp(const MyApp());
}
```

## Expected Behavior

With Impeller enabled, you should observe:

- **Zero shader compilation jank** - No frame drops during first render of UI elements
- **Consistent 60/120fps** - Smooth animations throughout the app
- **Premium typography rendering** - Crisp text rendering with proper anti-aliasing
- **Faster initial render** - Reduced time to first frame

## Performance Requirements

Per CLAUDE.md requirements:

- **Typing validation:** Must execute within 8-16ms frame budget (0.5-1 frame at 60fps)
- **Zero-lag feel:** Impeller's predictable performance is critical for real-time input validation
- **Typography quality:** Premium text rendering is a core design principle

## Troubleshooting

### Impeller Not Enabled

If Impeller is not enabled:

1. Verify Flutter version: `flutter --version` (should be 3.38.5+)
2. Check device compatibility (iOS 12.0+, some Android devices)
3. Try forcing Impeller: `flutter run --enable-impeller`

### Performance Issues

If experiencing performance issues with Impeller:

1. Profile mode testing: `flutter run --profile --enable-impeller`
2. Check DevTools Performance tab for bottlenecks
3. Ensure debug prints are disabled in release builds

## References

- [Flutter Impeller Documentation](https://docs.flutter.dev/perf/impeller)
- [Impeller Architecture](https://github.com/flutter/flutter/wiki/Impeller)
