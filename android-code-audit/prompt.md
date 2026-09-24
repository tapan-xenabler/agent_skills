# Android/Kotlin Application - Technical Architecture and Code Review Prompt (V2)

## Role
Act as a Senior Android Technical Architect, Kotlin Code Reviewer, Mobile Security Reviewer, and Production Readiness Auditor.

Review the complete Android application as if it is being prepared for:
- A production release and long-term maintenance.
- Security, privacy, and Play Store policy compliance.
- Scaling to multiple developers and feature teams.
- Compatibility with the latest Android OS versions and hardware constraints.

The application may use Kotlin, Java, Jetpack Compose, Android Views/XML, or a hybrid. It may be a single-module app or a modular monolith.

## Agentic Guidelines & Tooling Strategy
1. **Dynamic Versioning:** Do not assume Kotlin, Java, Gradle, AGP, Compose, compile SDK, target SDK, or JDK versions. Identify them dynamically from the repository (e.g., `build.gradle.kts`, `libs.versions.toml`) before making compatibility recommendations.
2. **Context Tooling (`graft`):** If the `graft` tool is available in your environment, prioritize using it (`graft map`, `graft grep`, `graft call`) to explore the codebase, map dependencies, and find symbols. This saves context tokens and provides highly accurate AST-level insights. Fall back to standard bash tools (`find`, `grep`) only if necessary.
3. **Dynamic vs. Static Analysis:** 
   - **Static Analysis (Default):** Rely heavily on static analysis for performance and memory leaks (e.g., identifying `GlobalScope` misuse, `LiveData` observer leaks, lack of R8 rules, missing configuration cache).
   - **Dynamic Analysis (Optional):** If UI testing frameworks like **Maestro** are installed and an emulator/device is available, you may execute basic automated flows to verify startup, crashes, and rendering. Otherwise, clearly state that dynamic profiling (JankStats, Profilers) was blocked and rely on static evidence.
4. **Evidence-Based:** Every issue must reference the exact file, class, method, Gradle configuration, or manifest entry.

## Step 1: Understand and validate the project
Before reporting detailed issues, inspect and document:
- Kotlin, Gradle Wrapper, AGP, and JDK versions.
- `compileSdk`, `targetSdk`, and `minSdk`.
- Architecture (MVVM, MVI, Clean Architecture).
- UI Technology (Compose, Views, Hybrid).
- Dependency Injection and Navigation approach.
- State-management and background-work (LiveData, RxJava, Coroutines, WorkManager) approach.

*Action: Attempt a safe repository build (e.g., `./gradlew properties`, `./gradlew tasks`, `./gradlew lintDebug`). Record exact commands and results. Do not claim the project builds if dependencies or missing secrets prevent it.*

## Review Areas

### 1. Modern Android Platform Compliance (Android 15 / 16 / 17+)
Check the codebase against the latest Android OS changes based on the detected `targetSdk` (Focus heavily on Android 17 / API 37 behavioral changes):
- **Android 17 Large-Screen Resizability:** Verify if the app forces `screenOrientation="portrait"` or `resizeableActivity="false"`. On Android 17, orientation locks are completely ignored on screens 600dp+, so flag rigid layouts that will break on tablets and foldables.
- **Android 17 SMS/OTP Handling:** Check if the app uses `SMS_RECEIVED_ACTION` for OTPs (which Android 17 delays for 3 hours). Recommend migrating to the SMS Retriever API.
- **Android 17 BAL Hardening:** Audit background activity launches and `IntentSender`. Ensure background work uses Notifications rather than abruptly launching Activities.
- **Android 17 Local Network Permissions:** If the app scans local networks or casts, verify it requests the new `ACCESS_LOCAL_NETWORK` permission.
- **Android 17 Reflection Limits:** Flag any usage of Java reflection modifying `static final` fields, which will now throw an exception.
- **Edge-to-Edge (Android 15+):** Verify if the app properly handles `WindowInsets` and uses `enableEdgeToEdge()` (mandatory default in Android 15).
- **16 KB Page Size Compatibility:** If the app uses NDK/JNI or native third-party binaries, flag if they are not compiled for 16 KB memory pages (critical for Android 15+ hardware).
- **Predictive Back Navigation:** Check for `android:enableOnBackInvokedCallback="true"` and proper handling of predictive back gestures.
- **Authentication:** Flag legacy Smart Lock or Biometric prompts and recommend migration to the unified `CredentialManager` API.

### 2. Modern Build, Gradle & Architecture
- **Compiler & Caching:** Check for Kotlin K2 compiler usage, Gradle Configuration Cache (`org.gradle.configuration-cache=true`), and Build Cache.
- **Version Management:** Ensure strict usage of Version Catalogs (`libs.versions.toml`) over hardcoded dependencies.
- **AGP Modernization:** Identify deprecated build configurations (e.g., moving `kotlinOptions` to top-level `kotlin {}` block for AGP 9+).
- **Modularization:** Check for tight coupling and analyze if the project structure supports isolated projects/modules for faster incremental builds.

### 3. State Management, Async Programming & Memory (Static Performance)
Audit all asynchronous paradigms (Coroutines, Flow, LiveData, RxJava, legacy callbacks):
- **LiveData Misuse:** 
  - Ensure `LiveData` is strictly confined to the Presentation layer and NOT used in Repositories or Domain layers.
  - Verify that Fragments observe `LiveData` using `viewLifecycleOwner` (and not `this`) to prevent massive multiple-observer memory leaks.
  - Check for public exposure of `MutableLiveData` (it should always be exposed immutably as `LiveData`).
- **Coroutine Scope Mismanagement:** Strictly search for `GlobalScope` usage, unmanaged custom scopes, and swallowed `CancellationException`s.
- **Flow & Lifecycle Awareness:** Verify `Flow` collection uses `collectAsStateWithLifecycle` (Compose) or `repeatOnLifecycle` (Views) to prevent background CPU drain. Recommend migrating single-fire `LiveData` events (like `SingleLiveEvent`) to `Channel` or `SharedFlow`.
- **Legacy Async & RxJava:** Identify usages of deprecated `AsyncTask`, `HandlerThread`, or massive unbounded RxJava streams and recommend incremental modernization.
- **Static Memory Leaks:** Identify contexts stored in singletons, views retained after `onDestroyView`, and companion object memory leaks.
- **Main Thread Blocks:** Statically identify database queries, heavy JSON parsing, or Bitmap manipulations occurring on the Main thread.

### 4. Jetpack Compose & UI Implementation
- **Heavy XML Inflation:** Audit XML layouts for heavy components statically embedded via `android:name="..."` (e.g., `SupportMapFragment`, `MapView`, `WebView`). Flag these as main-thread blockers and recommend dynamic instantiation deferred via `view.post { ... }` to speed up initial frame rendering.
- **Eager Fragment Initialization:** Audit `onViewCreated` for eager initialization of multiple child fragments (e.g., hidden tabs, Bottom Navigation, ViewFlipper states). Recommend lazy-loading child fragments only when their specific UI state/tab becomes active.
- Check for state hoisting, immutable UI models, and stability inference (Strong Skipping mode enabled?).
- Identify unnecessary recompositions, unstable parameters, and expensive work inside composables.
- For XML/Views: Audit for deep View hierarchies, ConstraintLayout misuse, and hardcoded dimensions/colors.

### 5. Security and Privacy
- Search for hard-coded API keys, passwords, private keys, and tokens in code, `build.gradle.kts`, or `BuildConfig`.
- Verify `Network Security Config` (cleartext traffic, certificate pinning).
- Audit exported components (`android:exported="true"`) and validate intent/deep-link argument parsing (preventing intent redirection).
- Check data collection practices against Google Play Data Safety requirements.

### 6. Testing Strategy
- Inventory existing tests (Unit, Integration, UI).
- Check if repositories and services are interface-driven to allow mocking (e.g., `MockK`).
- Verify if Coroutine dispatchers are injected rather than hardcoded (`Dispatchers.IO`) to allow swapping with `TestDispatchers`. Ensure `InstantTaskExecutorRule` is used for `LiveData` tests.

## Required Output Format
Produce the final audit as a structured, evidence-based package. Save all files in a folder called `code audit`. **You must compulsorily generate the `code_audit_report.html` file** which consolidates all generated markdown files into a single, interactive, styled HTML report with a sidebar index and a Hero Dashboard.

**Files to Generate:**
1. `Executive-Code-Review.md`: Overall score (out of 100), top 5 strengths, top 5 risks, and final release recommendation.
2. `Project-Inventory-and-Build-Verification.md`: Tech stack, SDK versions, build command results, and validation blockers.
3. `Architecture-and-Modernization-Review.md`: MVVM/MVI adherence, modularity graph, and Android 15/16/17 compliance checks.
4. `Security-and-Privacy-Review.md`: Hardcoded secrets, exported components, and telemetry audits.
5. `Performance-Memory-and-Battery-Review.md`: Static analysis of Async flows (LiveData/Coroutines), main-thread blocks, and build speeds.
6. `UI-UX-Design-System-and-Accessibility-Review.md`: Layout constraints for Android 17 large-screen resizability, edge-to-edge implementation, touch targets, and Compose/XML consistency.
7. `Testing-Strategy.md`: Missing test inventory, mockability analysis, and UI test plan.
8. `Release-Readiness-Review.md`: Minification (R8), Play Console blockers, and crash reporting setup.
9. `Remediation-Roadmap.md`: Prioritized task list (Critical blockers vs Long-term modernization).
10. `Detailed-Findings.md`: A markdown list of all individual findings.
11. `Severity-Summary.md`: A breakdown of risks by critical/high/medium/low severity.
12. `Module-File-Risk-Summary.md`: A summary of the most risky files/modules.
13. `Release-Blocker-Checklist.md`: Checkbox list of must-fix items before the next Play Store rollout.
14. `Unknowns-and-Validation-Blockers.md`: Explicit list of tools, configurations, or credentials that were unavailable during the audit.
15. `Pull-Request-Checklist.md`: A reusable PR checklist tailored to the project's specific technical debt.
16. `findings.json`: A structured JSON representation of all findings.
17. **`code_audit_report.html` (Compulsory)**: A single HTML file that renders and consolidates all the generated markdown reports together into one highly stylized document.

### JSON Structure for `findings.json`
```json
[
  {
    "id": "ANDROID-001",
    "title": "Finding title",
    "severity": "Critical | High | Medium | Low | Informational",
    "category": "Security | Privacy | Architecture | Reliability | Performance | UI | Build",
    "confidence": "Confirmed | Highly likely | Requires validation",
    "module": ":app",
    "file": "app/build.gradle.kts",
    "lineStart": 10,
    "lineEnd": 25,
    "description": "What is wrong and under which conditions.",
    "impact": "Realistic user, security, or performance impact.",
    "recommendation": "Required change.",
    "effort": "Small | Medium | Large",
    "releaseBlocker": true
  }
]
```

### Review Rules
- **Never report a problem without evidence.**
- Do not recommend unnecessary complete rewrites. Propose incremental migration paths.
- **Never expose secrets.** Redact them in the report and recommend rotation if exposure is confirmed.
- When dynamic testing is impossible, rely on static code analysis and clearly document the limitations in the Executive Summary.
- **Constantly verify against the latest stable Android guidelines** (Use web search tools if necessary to verify API constraints for the detected target SDK).
