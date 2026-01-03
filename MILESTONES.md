# **Red Letter: Implementation Plan**

This plan prioritizes a vertical "thin slice" of the core Practice Engine to validate the high-performance UI and learning science logic before expanding horizontally into persistence and synchronization.

## **Milestone 1: The Practice Engine (The Vertical Slice)**

**Goal:** Prove the end-to-end practice loop for a single passage.

* **Core Practice Loop (In-Memory):** Implement the Acquisition sequence: Impression (Read Aloud), Reflection, Scaffolding (Cloze Ladder), Prompted (Hints), and Reconstruction (Full Recitation).  
* **Rendering Engine:** Establish the Impeller-based typography rendering pipeline.  
* **Interactions:** Refine interactions, transitions, and animations for a tight and intuitive experience.

## **Milestone 2: Local Data Layer (Drift)**

**Goal:** Transition to a "local-first" architecture using a reactive relational model.

* **Drift Schema:** Implement the SQLite schema optimized for the "Client-Side Join" between static passages and user progress.  
* **Static Registry:** Seed the local database with an initial translation and command set.  
* **Reactive UI:** Build "The Living List" driven by Drift Streams to ensure UI-wide reactivity to mastery changes.

## **Milestone 3: Scheduling Engine (SRS) & Practice Refinements**

**Goal:** Implement the "Silent Orchestrator" and align Practice Mode with the new Acquisition algorithm.

* **FSRS Implementation:** Build the client-side FSRS logic (Stability, Difficulty, Retrievability) using the `fsrs` package.  
* **Review Queue:** Logic to query Drift for due items and prioritize the daily practice queue.
* **Acquisition Logic:** Refine the Practice Engine to match the new "Cloze Ladder" design (clause-based rotation vs random occlusion) and add on-demand hints.

## **Milestone 4: Identity & Compliance Gate**

**Goal:** Establish the legal and technical foundation for cloud processing.

* **Auth Flow:** Implement Firebase Anonymous-to-Permanent conversion.  
* **Consent Architecture:** Implement the GDPR requirements for processing sensitive religious data.  
* **Firestore Security:** Deploy rules to enforce /users/{userId} isolation.

## **Milestone 5: Sync & Conflict Resolution**

**Goal:** Enable real-time synchronization with an offline-first fallback.

* **Differential Sync:** Implement background reconciliation between Drift and Firestore.  
* **Mutation Queue:** Build sequential replay for handling recovery from extended offline periods.  
* **Optimistic UI:** Ensure all cloud interactions are side-effects that do not block the Practice Engine.

## **Milestone 6: Internationalization & Rights**

**Goal:** Support multiple translations and non-Latin scripts.

* **I18n Framework:** Standardize UI strings via .arb and implement the Version Provider for punctuation/capitalization variations.  
* **Unicode Support:** Validate typing engine performance for Greek, Hebrew, and CJK scripts.  
* **Rights Management:** Implement the metadata layer for scripture licensing compliance.

## **Milestone 7: Hardening & Export**

**Goal:** Production-grade privacy tools and system reliability.

* **Privacy Tooling:** Implement recursive "Delete My Account" and JSON "Data Export" features.  
* **Telemetry:** Finalize Firebase Crashlytics with IP anonymization and PII scrubbing enabled.

### **Critical Path Analysis**

1. **Vertical (M1):** Validates the "feel" and the core learning theory.  
2. **Horizontal (M2-M3):** Transforms the app into a functional utility (retention).  
3. **Cloud (M4-M5):** Handles the complexity of cross-device state and compliance.  
4. **Final (M6-M7):** Prepares the system for a global, multi-user production environment.