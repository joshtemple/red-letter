# Red Letter

A mobile memorization app for internalizing the commands of Jesus.

## Overview

Red Letter is a Flutter-based iOS/Android application designed for scripture memorization with a focus on the words of Jesus. The app features a text-first, premium typography experience with five progressive practice modes that fade assistance as mastery increases.

## Tech Stack

- **Frontend:** Flutter (Dart) with Impeller rendering engine
- **Local Database:** Drift (reactive relational layer over SQLite)
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Architecture:** Client-centric, offline-first with cloud sync

## Project Structure

```
lib/
├── main.dart           # App entry point
├── models/             # Data models
├── database/           # Drift database setup
├── screens/            # UI screens (practice modes)
├── widgets/            # Reusable UI components
└── services/           # Services (SRS engine, Firebase sync)
```

## Development Setup

### Prerequisites

- Flutter SDK 3.38.5+
- Dart 3.10.4+
- Xcode (for iOS development)
- Android Studio (optional, for Android development)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app with Impeller rendering:
   ```bash
   flutter run --enable-impeller
   ```

See [IMPELLER.md](IMPELLER.md) for detailed Impeller configuration and verification.

## Core Features

### Practice Engine Modes (Sequential)

1. **Impression Mode** - Full text + visual mnemonic display
2. **Semantic Mode** - Mandatory reflection prompt
3. **Scaffolding Mode** - Variable ratio occlusion
4. **Prompted Mode** - Blank input with sparse prompting
5. **Reconstruction Mode** - Total independent recall

### Spaced Repetition System

Modified SuperMemo SM-2 algorithm running entirely client-side for zero-latency performance.

## Privacy & Compliance

This app processes Special Category Data (religious beliefs) under GDPR Article 9. Features:

- Mandatory consent modal before persistence/sync
- Anonymous-first (Firebase Anonymous UID)
- Zero third-party analytics
- AES-256 encryption at rest, TLS 1.3 in transit
- Data rights: Delete My Account & Data Export

## Documentation

- [DESIGN.md](DESIGN.md) - Detailed design philosophy and architecture
- [MILESTONES.md](MILESTONES.md) - Development milestones and critical path
- [OVERVIEW.md](OVERVIEW.md) - Project overview
- [IMPELLER.md](IMPELLER.md) - Impeller rendering configuration and verification
- [CLAUDE.md](CLAUDE.md) - AI assistant guidelines

## License

Copyright © 2026. All rights reserved.
