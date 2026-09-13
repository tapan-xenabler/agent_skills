---
name: ios-code-audit
description: Comprehensive Senior iOS Technical Architecture, Security, Performance, and SwiftUI Code Review auditor for production release readiness.
---

# iOS Code Audit & Production Release Readiness Skill

This skill equips Antigravity to act as a Senior iOS Technical Architect and SwiftUI Code Reviewer to perform end-to-end, evidence-based code audits on any iOS application workspace.

## Objectives & Review Methodology

When invoked or requested to perform an iOS code audit:

1. **Project Inspection & Environment Inventory**:
   - Inspect build settings, Swift version, target SDKs, scheme configurations (`.xcconfig`), `Info.plist`, entitlements, SPM dependencies, and CI/CD pipelines.
   - Audit directory structure for dual-maintenance or orphaned files.

2. **Core Audit Domains**:
   - **Architecture**: Clean Architecture / MVVM-C separation, Dependency Injection, tight coupling, singleton usage.
   - **Security & Privacy**: Hardcoded API keys/secrets, plaintext logging of headers/tokens, Keychain vs. UserDefaults usage, session erasure in `logout()`, `PrivacyInfo.xcprivacy` compliance, and missing `Info.plist` usage strings (`NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, etc.).
   - **Performance**: Main-thread blocking (JSON decoding in view bodies, logging serialization), Realm object thread boundaries (`.freeze()`), and Xcode Instruments profiling matrix.
   - **Swift & SwiftUI Quality**: `@StateObject` lifecycle, state synchronization, structured concurrency, memory leak / retain cycle hazards, dead code, and `print()` debugging statements.
   - **UI & Accessibility**: Design token usage (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`), VoiceOver labels/hints, Dynamic Type scaling, and minimum 44x44pt touch targets.
   - **Testability**: Automated test coverage (Swift Testing / XCTest), mock initializers, deterministic testing strategy.
   - **Build & CI/CD**: XCConfig environment consistency, Fastlane configuration, build variant correctness.

3. **Deliverables Standard**:
   Generate 8 structured Markdown documents + 1 machine-readable `findings.json` in the workspace root:
   - `Executive-Code-Review.md`
   - `Detailed-Findings.md`
   - `Architecture-Review.md`
   - `Security-and-Privacy-Review.md`
   - `Performance-Review.md`
   - `UI-UX-and-Accessibility-Review.md`
   - `Testing-Strategy.md`
   - `Remediation-Roadmap.md`
   - `findings.json`

4. **Team Export Generation**:
   Automatically run a Python script to combine all Markdown review files into:
   - `Full-Technical-Code-Review-Report.html` (Interactive HTML with Table of Contents and Mermaid diagrams)
   - `Full-Technical-Code-Review-Report.pdf` (Formatted PDF for executive/team distribution)
