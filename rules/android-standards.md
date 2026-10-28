# Android Project Standards & Coding Guidelines

This project strictly adheres to the four foundational Android engineering specifications maintained in the `docs/` directory:

1. **Architecture & Clean Code** ([`docs/Architecture.md`](./docs/Architecture.md)):
   - Follow MVVM with Unidirectional Data Flow (UDF) in Jetpack Compose.
   - Separate Stateful routes from Stateless UI screen composables.
   - Screen state must be immutable (`StateFlow<UiState>`); one-off events must use `Channel<UiEffect>`.
   - Never use `runBlocking` in production code, especially in OkHttp interceptors or UI threads.
   - Jetpack Navigation 3 keys must be deterministic and stable; support predictive back handling.
   - Handle Edge-to-Edge window insets explicitly (`statusBarsPadding()`, `navigationBarsPadding()`, and `imePadding()` on inputs).
   - Depend on repository interfaces bound via Dagger Hilt (`@Binds`); use `WorkManager` for background offline sync.
   - Dispatch all telemetry exclusively via `AnalyticsTracker` with type-safe `AnalyticsEvent` (never import `FirebaseAnalytics` in UI/ViewModel; zero PII in event params).
   - Test reactive viewmodel flows using CashApp Turbine and Coroutines Test.

2. **Security & Privacy (OWASP MASVS & Google Play)** ([`docs/Security.md`](./docs/Security.md)):
   - Zero tolerance for committed secrets (API keys, keystores, or credentials).
   - Cleartext traffic is disabled; enforce TLS 1.3/1.2 and certificate pinning on production endpoints (`app-api.askjiya.ai`).
   - Hardware-backed Android KeyStore AES-256-GCM required for local sensitive tokens and care data.
   - Never log authorization bearer tokens or client secrets to logs or analytics.
   - Native C++ shared libraries must support 16 KB memory page size alignment (`-Wl,-z,max-page-size=16384`).
   - Gate audio recording behind prominent in-context disclosure before triggering `RECORD_AUDIO`.
   - Provide verified in-app and web account/data deletion flow for Google Play compliance.
   - Android components must default to `android:exported="false"`.

3. **Design System & Accessibility (Google Play & WCAG2Mobile)** ([`docs/Design.md`](./docs/Design.md)):
   - Use design tokens from `MaterialTheme.colorScheme` and `AppColors` (never hardcode raw hex colors in screen composables).
   - Buttons, text inputs, and interactive cards must strictly use `10px` corner radius (`RoundedCornerShape(10.dp)`).
   - Plus Jakarta Sans is the exclusive font family.
   - Zero hardcoded strings in composables; use `stringResource(R.string.*)`.
   - Exclusively use RTL-friendly `Start` / `End` directionality (no `Left` / `Right`).
   - **Touch Targets**: Minimum 48dp x 48dp with 8dp spacing between interactive elements (`Modifier.minimumInteractiveComponentSize()`).
   - **Contrast**: Adhere to WCAG AA/AAA (≥ 4.5:1 for normal text, ≥ 3.0:1 for large text and graphical components).
   - **Dynamic Type**: Layouts must scale up to 200% font size without clipping (use `heightIn(min = ...)` instead of fixed `height(...)`).
   - **TalkBack Semantics**: Every interactive icon or image MUST have an informative, localized `contentDescription` (no `null` on functional elements); use `semantics(mergeDescendants = true)` for grouped components and `liveRegion` for real-time chat/voice updates.

4. **Product Requirements & Acceptance** ([`docs/Requirement.md`](./docs/Requirement.md)):
   - Verify all feature implementations against target caregiver personas and user stories.
   - Ensure graceful offline degradation with Room DB caching, offline status indicators, and UTC Last-Write-Wins conflict resolution.
