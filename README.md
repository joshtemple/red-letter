---
last_updated_commit: 1492a05ef3dcc495e3f75c997dafa44586f43444
---

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

### Practice Flow (Sequential)

1. **Impression Step** - Full text + visual mnemonic display
2. **Reflection Step** - Mandatory reflection prompt (forces semantic encoding)
3. **Scaffolding Step** - Progressive 4-level occlusion ladder:
   - **L1 (Random Words)**: Random words hidden (3 rounds)
   - **L2 (First Two Words)**: Only first 2 words of clause shown (1 round)
   - **L3 (Rotating Clauses)**: One full clause hidden at a time (rotating)
   - **L4 (Full Passage)**: Total independent recall (replaces Reconstruction)

### Spaced Repetition System

Modified FSRS algorithm running entirely client-side for zero-latency performance.

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
- [TYPOGRAPHY.md](TYPOGRAPHY.md) - Typography system and performance optimizations
- [ACQUISITION_LADDER_INTEGRATION.md](ACQUISITION_LADDER_INTEGRATION.md) - M3 Advanced Acquisition Ladder integration guide
- [CLAUDE.md](CLAUDE.md) - AI assistant guidelines

## License

Copyright © 2026. All rights reserved.

