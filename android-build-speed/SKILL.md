---
name: android-build-speed
description: >-
  Use this skill when the user reports slow Android Gradle builds — clean or
  incremental. Covers: activeVariant beforeVariants filtering (biggest win for
  multi-flavor projects with 10+ flavors), JVM/GC tuning scaled to machine RAM,
  Kotlin compilerOptions (AGP 9+ API replacing kotlinOptions), disabling unused
  build features, Gradle wrapper version upgrade, and Fastlane clean opt-in fixes.
  Activate whenever the user says builds are slow, incremental builds lag,
  UI changes take too long to compile, or Gradle is taking too much time.
---

# Android Build Speed Optimization

## When to Activate
- "Build is slow / taking too long"
- "Incremental builds are slow"
- "Small UI changes take forever"
- "Gradle is slow" / "Too many flavors slowing down build"
- "How do I speed up Android builds?"

---

## Step 1 — Audit First (Read Before Touching Anything)

Read ALL of these files before making any changes:
- `gradle.properties`
- `gradle/wrapper/gradle-wrapper.properties`
- `gradle/libs.versions.toml`
- `app/build.gradle.kts`
- `settings.gradle.kts`
- `fastlane/Fastfile` (if present)

**Identify:**
- Current GC algorithm — `ParallelGC` is bad for large heaps, replace with `G1GC`
- Number of product flavor dimensions and their names (key for `beforeVariants`)
- AGP version — determines valid Gradle version range and `kotlinOptions` API
- Whether `kotlinOptions {}` is inside `android {}` — this causes an error in AGP 9+
- Whether `clean` is hardcoded in Fastlane lanes (anti-pattern)
- Ask the user their machine RAM if not clear from context

---

## Step 2 — activeVariant Filter (MOST IMPACTFUL for Multi-Flavor Projects)

With N flavors × M environments × 2 build types, AGP configures all variants
even for incremental builds. `beforeVariants` disables all unused debug variants
at **configuration time** — zero tasks are generated for them.

**Impact:** 50 flavor project goes from 100+ configured variants → 2 (1 debug + release set).

### 2a. Add to `gradle.properties`

```properties
# ─── Active variant for incremental dev builds ────────────────────────────────
# Only this flavor combo compiles in DEBUG. Release always builds all variants.
# Change to match the flavor you are currently developing.
# Valid values: match the product+environment flavor names joined, e.g. oparkQa, clientAStaging
# Override on CLI without editing this file: ./gradlew assembleXxxDebug -PactiveVariant=xxx
activeVariant=<most_used_debug_flavor>
```

### 2b. Add `beforeVariants` block in `app/build.gradle.kts`

Find `androidComponents {`. Add `beforeVariants` as the **FIRST** block inside it,
BEFORE any existing `onVariants` block. If `androidComponents` doesn't exist, create it.

```kotlin
androidComponents {
    // ── Active variant filter ─────────────────────────────────────────────────
    // Disables all debug variants except the one in `activeVariant` (gradle.properties).
    // This runs at CONFIGURATION time — disabled variants produce ZERO tasks.
    // Release variants are NEVER filtered — they always build normally.
    beforeVariants { variantBuilder ->
        val buildType = variantBuilder.buildType ?: return@beforeVariants
        if (buildType == "debug") {
            // Combine all flavor dimension values into one string
            // e.g. dimensions ["product"="opark", "environment"="qa"] → "oparkQa"
            val flavorCombo = variantBuilder.productFlavors
                .map { (_, value) -> value }
                .joinToString("")
            val activeVariant = project.findProperty("activeVariant")
                ?.toString() ?: "<default_flavor>"
            if (!flavorCombo.equals(activeVariant, ignoreCase = true)) {
                variantBuilder.enable = false
            }
        }
        // Release variants: ALWAYS kept enabled — never touched by this filter
    }

    onVariants(selector().all()) { variant ->
        // ... existing onVariants code stays here unchanged ...
    }
}
```

### 2c. How to switch active variant

```bash
# Option 1: Edit gradle.properties (persists across builds)
activeVariant=vparkUat

# Option 2: CLI override — no file edit needed
./gradlew assembleVparkUatDebug -PactiveVariant=vparkUat

# Option 3: Fastlane — always pass the property
gradle(task: "assembleClientADebug", properties: { "activeVariant" => "clientA" })
```

---

## Step 3 — gradle.properties JVM/GC Tuning

**Always ask the user their machine RAM before applying.** Scale accordingly:

| Machine RAM | Gradle `-Xmx` | Kotlin daemon `-Xmx` | `workers.max` |
|-------------|--------------|----------------------|---------------|
| 8 GB        | 4g           | 2g                   | 4             |
| 16 GB       | 8g           | 4g                   | 8             |
| 32 GB       | 12g          | 6g                   | 12            |

Apply this full template (adjust values per table above):

```properties
# ─── Parallelism ──────────────────────────────────────────────────────────────
org.gradle.parallel=true
org.gradle.configuration-cache=true
org.gradle.configuration-cache.parallel=true
org.gradle.workers.max=8
org.gradle.tooling.parallel=true
org.gradle.caching=true
org.gradle.vfs.watch=true

# ─── JVM / GC ─────────────────────────────────────────────────────────────────
# G1GC is far better than ParallelGC for heaps >= 4 GB:
# lower pause times, better throughput for Kotlin compilation workloads
org.gradle.jvmargs=-Xmx8g -Xms2g -XX:MaxMetaspaceSize=1g \
  -XX:+UseG1GC \
  -XX:SoftRefLRUPolicyMSPerMB=1 \
  -XX:ReservedCodeCacheSize=512m \
  -XX:+HeapDumpOnOutOfMemoryError \
  -Dfile.encoding=UTF-8

kotlin.daemon.jvmargs=-Xmx4g -Xms512m \
  -XX:+UseG1GC \
  -XX:ReservedCodeCacheSize=384m \
  -Dfile.encoding=UTF-8

# ─── Kotlin incremental ───────────────────────────────────────────────────────
kotlin.incremental=true
kotlin.incremental.useClasspathSnapshot=true
kotlin.build.report.output=file

# ─── KSP (Room, Hilt) — only ksp.useKSP2 if Kotlin 2.0+ ─────────────────────
ksp.incremental=true
ksp.incremental.intermodule=true
ksp.useKSP2=true

# ─── KAPT (legacy) ───────────────────────────────────────────────────────────
kapt.incremental.apt=true

# ─── Android ─────────────────────────────────────────────────────────────────
android.useAndroidX=true
android.nonTransitiveRClass=true
android.enableJetifier=false
android.experimental.cacheCompileLibResources=true
android.enableR8.fullMode=false

# ─── Network ──────────────────────────────────────────────────────────────────
org.gradle.internal.repository.max.retries=3
systemProp.org.gradle.internal.http.connectionTimeout=120000
```

---

## Step 4 — Kotlin Compiler Options (AGP 9+ API)

**IMPORTANT:** `kotlinOptions {}` inside `android {}` was removed in AGP 9.0.
It causes: `Unresolved reference 'kotlinOptions'`

Remove any `kotlinOptions {}` block from inside `android {}`.

Add this import at the top of `app/build.gradle.kts`:
```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
```

Add this top-level block **after** the `android {}` closing brace:
```kotlin
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
        freeCompilerArgs.addAll(
            "-opt-in=kotlin.RequiresOptIn",
            "-Xbackend-threads=0",  // use all CPU cores for IR code-generation
        )
    }
}
```

---

## Step 5 — Disable Unused Build Features

Each enabled feature adds tasks to the build graph — even when unused.

```kotlin
buildFeatures {
    viewBinding = true   // keep only what the project actually uses
    buildConfig = true
    // Explicitly disable everything else:
    aidl = false
    renderScript = false
    shaders = false
    mlModelBinding = false
}
```

Also clean up the debug `buildType`:
```kotlin
getByName("debug") {
    isMinifyEnabled = false
    isShrinkResources = false
    // Do NOT add proguardFiles for debug — R8 is off, parsing them wastes config time
}
```

Add packaging exclusions to remove duplicate META-INF merge warnings:
```kotlin
packaging {
    resources {
        excludes += setOf(
            "META-INF/LICENSE.md",
            "META-INF/LICENSE-notice.md",
            "META-INF/NOTICE.md",
            "META-INF/DEPENDENCIES",
            "**/kotlin/**",
            "DebugProbesKt.bin",
        )
    }
}
```

---

## Step 6 — Gradle Wrapper Version

Check `gradle/wrapper/gradle-wrapper.properties`. Upgrade to latest stable
compatible with the project's AGP:

| AGP version | Min Gradle | Recommended (Sep 2026) |
|-------------|------------|------------------------|
| 8.x         | 8.0        | Latest 8.x             |
| 9.x         | 9.1        | 9.7.1                  |

**ALWAYS verify the distribution URL returns HTTP 200 before writing it.**
A 404 URL breaks all project syncs.

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.7.1-bin.zip
```

---

## Step 7 — Fastlane (if Fastfile exists)

Fix these anti-patterns:

**1. Hardcoded `clean` — make opt-in:**
```ruby
# ❌ Old — destroys build cache every time
gradle(task: "clean assemble#{task_variant}")

# ✅ New — clean only when explicitly requested
should_clean = options[:clean].to_s == 'true'
gradle_task = should_clean ? "clean assemble#{task_variant}" : "assemble#{task_variant}"
gradle(task: gradle_task, properties: { "activeVariant" => (flavor || "") })
```

**2. Remove `--no-configuration-cache`** — configuration cache is stable, keep it on.

**3. Always pass `activeVariant` property** to every `gradle()` call so the
property is always defined (release ignores it; debug uses it).

---

## Step 8 — Verify

```bash
./gradlew :app:assemble<ActiveVariant>Debug
```

Confirm the output shows:
- `Configuration cache entry stored` (first run)
- `Configuration cache entry reused` (subsequent runs)
- Task names **only** contain the active variant — no other flavor task names
- Most tasks show `UP-TO-DATE` on the second run

---

## Expected Results After Applying

| Scenario | Before | After |
|---|---|---|
| Incremental build (50 flavors) | Configures 100+ variants | Configures 2 variants |
| Layout XML change | Full resource merge for all debug variants | Only active variant resource merge |
| Kotlin file change | Full recompile (ParallelGC GC pauses) | Incremental + G1GC smooth throughput |
| Second build (config cache) | Full configuration phase | Configuration phase skipped entirely |
