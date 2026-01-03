# **Technical Design: Red Letter**

## **1\. Introduction**

This document outlines the technical architecture for the **Red Letter** memorization app. The system is designed as a high-performance, offline-first mobile application that synchronizes state across devices using a serverless backend. The primary engineering goal is to create a "transparent" technology layer—one where the complexity of synchronization and algorithmic scheduling never interrupts the user's meditative focus on the text.

## **2\. Tech Stack**

* **Frontend:** **Flutter** (Dart). Chosen for its high-fidelity rendering engines (**Skia** and **Impeller**). Impeller ensures jank-free animations and perfectly anti-aliased typography, essential for a premium, text-focused experience.  
* **Backend-as-a-Service:** **Firebase**.  
  * **Authentication:** Firebase Auth, supporting **Anonymous-to-Permanent conversion**.  
  * **Database:** Cloud Firestore for real-time synchronization.  
  * **Storage:** Firebase Storage for hosting minimalist visual mnemonics.  
  * **Functions:** Cloud Functions for administrative tasks and data sanitization.

## **3\. System Architecture**

The application follows a **Client-Centric logic model**. To minimize latency and ensure a responsive feel, both the Practice Engine and the Scheduling Engine (SRS) reside entirely on the client.

* **Local Data Layer (Drift):** We use **Drift** (formerly Moor) as our primary local persistence engine.  
  * **Why Drift:** While Firestore has a median cache, it is primarily a document store. Drift is a reactive relational database built on top of SQLite. It allows us to perform high-performance SQL joins between static passage text and dynamic user progress.  
  * **Type Safety:** Drift uses code generation to provide a type-safe API for SQL queries, reducing runtime errors during complex data manipulations.  
  * **Reactivity:** Like Firestore, Drift supports Streams. When a user completes a session, the UI updates instantly because it is listening to a Drift stream that reacts to the underlying SQLite change.  
* **Synchronization:** Firestore serves as the "Source of Truth," reconciling the local Drift state with the cloud.

## **4\. Data Model**

The data model is bifurcated to optimize scalability and minimize redundant storage. We use the term **"Passage"** to represent a memorizable unit of text.

### **A. Global Registry (Static)**

This data is immutable and shared across all users, organized by translation. By isolating this in a public root collection, we ensure high-read efficiency.

* **Collection:** /public/translations/{translationId}/passages  
* **Fields:**  
  * id: Semantic ID (e.g., mat-5-44).  
  * text: The raw scripture text.  
  * reference: Human-readable book, chapter, and verse.  
  * mnemonicUrl: Path to the minimalist visual SVG/asset.  
  * tags: Array of themes for discovery.

### **B. User Progress (Dynamic)**

Contains metadata required for the SRS algorithm and user-generated content.

* **Collection:** /users/{userId}/progress  
* **Fields:**  
  * passageId: Foreign key to the global registry.  
  * masteryLevel: Enum representing the current Practice Mode.  
  * srsData: Object containing interval, easeFactor, repetitionCount, and nextReviewDate.  
  * semanticReflection: The user's personal summary (for Semantic Encoding).  
  * lastSync: Timestamp for differential sync logic.

### **C. Client-Side Join**

The Flutter client performs a relational join in memory (or via Drift's relational queries). This ensures that we don't store the full text of "Matthew 5:44" for every user, but rather a small metadata record that "decorates" the global passage with the user's specific mastery status.

## **5\. Technical Requirements**

* **State Persistence:** Aggregate results of a practice session (accuracy, speed, updated interval) are persisted to Drift immediately and queued for background sync to Firestore.  
* **The SRS Algorithm:** Implements the **FSRS (Free Spaced Repetition Scheduler)** algorithm. It tracks core variables including stability and difficulty. By adjusting these variables based on granular user performance—such as response speed and accuracy during the Reconstruction Mode—the engine dynamically optimizes review timing. Successful recall increases the interval based on the retrievability calculated by FSRS.
* **Practice Mode Algorithm (Acquisition):**
  * Read aloud two times
  * Reflection - what does this passage mean to you?
  * Cloze ladder on clauses
      * Round 1: Remove 1-2 content words per clause
      * Round 2: Delete 1 entire clause, rotate clause position until all have been covered
      * Round 3: Show only the first 2 words of each clause
  * Full recitation, with on demand hints
  * Full recitation: On success, move into Review set
  * At any point, on failure: reduce one level and try again
* **Review Mode Algorithm:**
  * Use FSRS (Free Spaced Repetition Scheduler)
  * Calculate heuristic from review performance (latency and accuracy/similarity) to determine difficulty
  * User-defined budget for working set size, top off with new cards (use Acquisition machine for new cards)

## **6\. Security & Privacy (GDPR & Article 9\)**

Given the nature of the app, data is categorized as **Special Category Data** under GDPR Article 9 (religious beliefs).

* **Explicit Consent:** To meet the rigorous requirements for processing sensitive information, the "Soft Sign-in" flow must include a mandatory consent modal. This modal explicitly informs the user that their session metrics and semantic reflections constitute religious data, ensuring they are fully aware of this classification before the memorization engine initiates local persistence or cloud synchronization.  
* **Authentication:** Users begin with an anonymous UID. No PII (email/name) is collected until the user chooses to upgrade their account for cross-device sync.  
* **Authorization:** Strict Firestore Security Rules ensure request.auth.uid \== userId.  
* **Data Privacy:** Zero third-party behavioral analytics. No Meta/Google/Mixpanel SDKs. Firebase Crashlytics is used with mandatory PII scrubbing and IP anonymization enabled.  
* **Encryption:** Data is encrypted at rest by Google Cloud (AES-256) and in transit via TLS 1.3.

## **7\. Compliance & User Rights**

To be robust for non-US users (GDPR/CCPA/LGPD), the system implements the following:

* **Right to Erasure (Forgetfulness):** A prominent "Delete My Account & Data" feature within the app triggers a recursive delete of the /users/{userId} tree and signs the user out.  
* **Right to Portability:** A "Data Export" feature generates a JSON/CSV bundle of the user's progress and semanticReflection fields from the Drift database.  
* **Data Residency:** For high-compliance scenarios, the Firebase project should be configured with a multi-region or European region (e.g., europe-west1) for Firestore, though the current design prioritizes global low-latency.  
* **Data Minimization:** We do not collect device identifiers, location data, or contact lists. The only "identifying" data is the user's optional email and their subjective reflections.

## **8\. Reliability & Latency**

* **Zero-Lag Typing Engine:** Validation logic must run within the 8ms–16ms frame budget. Validation is synchronous on the UI thread for instantaneous feedback.  
* **Optimistic UI Updates:** UI transitions trigger immediately. Local Drift state is updated first, with the cloud sync following as a background side-effect.  
* **Offline Queueing:** Sequential replay of a "Mutation Queue" handles reconciliation after extended offline periods.

## **9\. Scalability**

* **Database Scalability:** Firestore provides automatic sharding and horizontal scaling.  
* **Distributed Compute:** Client-side SRS logic ensures the backend primarily serves as a high-availability data relay, minimizing costs.

## **10\. Internationalization (i18n) & Localization (l10n)**

* **UI Localization:** Standard Flutter .arb files.  
* **Version Provider:** Handles punctuation and capitalization variations across different scripture translations.  
* **Unicode Support:** Dart's UTF-16 strings support non-Latin scripts (Greek, Hebrew, CJK).

## **11\. Dependencies & Trade-offs**

* **Ecosystem Dependency:** Heavy reliance on Google/Firebase.  
  * *Trade-off:* High velocity and low maintenance vs. vendor lock-in.  
* **Logic Distribution:** Client-side logic for SRS and Practice Engine ensures offline functionality and zero-latency interactions.

## **12\. Significant Obstacles & Hurdles**

* **Content Licensing & Rights:** Scripture versions have varied licensing. Requires a "Rights Management" metadata layer.  
* **Keystroke Performance:** Utilize a "Thin-Listener" pattern for text controllers, offloading string comparisons to a background isolate for longer passages.
