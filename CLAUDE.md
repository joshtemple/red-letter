---
last_updated_commit: 1492a05ef3dcc495e3f75c997dafa44586f43444
---

# CLAUDE.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

**Red Letter** is a mobile memorization app for internalizing the commands of Jesus. The design philosophy is "less is more" with a text-first, high-quality typography experience. Currently in active development (Milestone 3 in progress).

## Tech Stack

- **Frontend:** Flutter (Dart) - chosen specifically for Impeller rendering engine (jank-free animations, premium typography)
- **Local Database:** Drift (formerly Moor) - reactive relational layer over SQLite for type-safe queries and streams
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Architecture:** Client-centric, offline-first with cloud sync

## Core Architecture Principles

### Data Model Structure

The system uses a bifurcated data model to minimize storage and maximize scalability:

1. **Global Registry (Static)** - `/public/translations/{translationId}/passages`
   - Immutable scripture text shared across all users
   - Contains: passage ID (e.g., "mat-5-44"), text, reference, mnemonicUrl, tags

2. **User Progress (Dynamic)** - `/users/{userId}/progress`
   - Per-user metadata: passageId (FK), masteryLevel, srsData, semanticReflection, lastSync
   - Never duplicates the scripture text itself

3. **Client-Side Join**
   - Flutter/Drift performs relational joins in-memory
   - Decorates global passages with user-specific mastery status

### Practice Session Structure
 
The core learning and review loop follows a strict hierarchy:
 
1. **Session** - An end-to-end practice event for a single passage.
2. **Flow** - The type of session:
   - **Learning Flow**: For new passages (Impression -> Reflection -> Scaffolding).
   - **Review Flow**: For existing passages (Scaffolding L4 only).
3. **Step** - Sequential stages within a flow (e.g., Impression, Scaffolding).
4. **Scaffolding Level** - Progressive difficulty in the Scaffolding step:
   - **L1 (RandomWords)**: Random non-trivial words removed (N rounds).
   - **L2 (FirstTwoWords)**: Only first 2 words of each clause shown (1 round).
   - **L3 (RotatingClauses)**: One full clause hidden at a time (M rounds).
   - **L4 (FullPassage)**: 100% cloze deletion, no underlines (1 round).
5. **Round** - An atomic unit of practice within a Level.
6. **Lives** - User has 2 lives per Round. Losing all lives triggers regression to the previous Level (or restart of L1).

### Spaced Repetition System (SRS)

- **Algorithm:** FSRS algorithm running entirely client-side
- **Variables:** Stability, Difficulty, State, Due Date
- **Performance-based:** Adjusts based on response speed and accuracy
- **Zero-latency requirement:** Must run within 8-16ms frame budget

## Critical Constraints

### Performance Requirements

- **Typing validation:** Must execute within 8-16ms frame budget for zero-lag feel
- **Optimistic UI:** All updates happen to Drift first, cloud sync as background side-effect
- **Offline-first:** Full functionality without network, mutation queue for sync reconciliation

### Privacy & Compliance (GDPR Article 9)

This app processes **Special Category Data** (religious beliefs):

- **Mandatory consent modal** before any persistence/sync (explicitly inform users about religious data classification)
- **Anonymous-first:** Users start with Firebase Anonymous UID, no PII until they opt-in for sync
- **Firestore Security Rules:** Strict `request.auth.uid == userId` enforcement
- **Zero third-party analytics:** No Meta/Google/Mixpanel SDKs
- **Data rights:** Must implement "Delete My Account" (recursive delete) and "Data Export" (JSON/CSV)
- **Encryption:** AES-256 at rest, TLS 1.3 in transit

### Design Philosophy

- **Text-first interface:** Typography quality is paramount, feel like a premium book not a utility app
- **Minimal friction:** Zero barriers from app launch to practice session
- **No attention-hacking:** Respects user's mental space and quietude
- **Anti-patterns to avoid:**
  - Static cues that create "illusion of competence"
  - Rote memorization without semantic understanding
  - "Cheap" dopamine gamification

## Implementation Milestones

Per MILESTONES.md, the critical path is:

1. **M1:** Practice Engine vertical slice (in-memory, validate UI/UX feel)
2. **M2:** Drift local persistence (client-side join architecture)
3. **M3:** SRS scheduling engine (client-side FSRS)
4. **M4:** Auth + GDPR compliance gate
5. **M5:** Firestore sync + conflict resolution
6. **M6:** i18n/l10n + scripture rights management
7. **M7:** Privacy tooling + production hardening

## Known Technical Hurdles

- **Keystroke performance:** Use "Thin-Listener" pattern, offload string comparisons to background isolate for long passages
- **Unicode support:** Must handle Greek, Hebrew, CJK scripts in typing engine
- **Scripture licensing:** Requires rights management metadata layer
- **Vendor lock-in:** Heavy Firebase dependency (accepted trade-off for velocity)

