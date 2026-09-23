---
name: bitbucket-pr-agent
description: >-
  Setup, configure, and maintain Bitbucket Pipelines with Qodo PR-Agent (pragent) for
  automated AI pull request code reviews and descriptions using Google Gemini.
  Triggers on requests to add or set up PR Agent, Qodo, Bitbucket AI code review, or AI PR review pipeline.
---

# Bitbucket Pipelines + Qodo PR-Agent Skill

This skill automates the setup and configuration of **Qodo PR-Agent** (`pragent/pr-agent:latest`) within **Bitbucket Pipelines** using **Google Gemini** (via Google AI Studio) to provide automated, high-signal, contextual AI pull request reviews and summaries.

---

## Trigger Phrases

Activate this skill when the user asks any variation of:
- *"Add PR review pipeline using Qodo PR-Agent"*
- *"Setup Bitbucket pipeline with Qodo / PR-Agent"*
- *"Configure AI PR review in Bitbucket using Gemini"*
- *"Add `.pr_agent.toml` and `bitbucket-pipelines.yml` to this project"*
- *"Set up PR-Agent for Android / iOS / Web / Backend in Bitbucket"*

---

## Core Components

Integrating PR-Agent into any repository requires two root-level configuration files and two repository secrets:

1. **`bitbucket-pipelines.yml`**: Triggers a lightweight Docker step on pull request creation/updates, filters destination branches, pulls `pragent/pr-agent:latest`, and runs the review command against the PR.
2. **`.pr_agent.toml`**: Customizes reviewer persona, extra technical instructions, tone, and files/titles to ignore.
3. **Repository Variables**:
   - `GEMINI_API_KEY`: API key from Google AI Studio.
   - `BITBUCKET_BEARER_TOKEN`: Bitbucket Repository or Workspace Access Token with `pullrequests:read` and `pullrequests:write` permissions.

---

## Pre-Built Templates

Templates are available in this skill's directory:
- Pipeline template: [`templates/bitbucket-pipelines.yml`](./templates/bitbucket-pipelines.yml)
- Android / Kotlin config: [`templates/pr_agent_android.toml`](./templates/pr_agent_android.toml)
- iOS / Swift config: [`templates/pr_agent_ios.toml`](./templates/pr_agent_ios.toml)
- Web / TypeScript config: [`templates/pr_agent_web.toml`](./templates/pr_agent_web.toml)
- Generic / Backend config: [`templates/pr_agent_generic.toml`](./templates/pr_agent_generic.toml)

---

## Step-by-Step Setup Workflow

### Step 1: Detect Project Stack

Inspect the project files in the repository root to determine the primary language/platform:
- **Android**: Look for `build.gradle`, `build.gradle.kts`, `settings.gradle`, or `app/src/main/AndroidManifest.xml`.
- **iOS**: Look for `*.xcodeproj`, `*.xcworkspace`, or `Package.swift`.
- **Web / Frontend**: Look for `package.json`, `tsconfig.json`, `next.config.js`, or `vite.config.ts`.
- **Backend / Other**: Python (`requirements.txt`, `pyproject.toml`), Go (`go.mod`), Java/Kotlin backend (`pom.xml`), etc.

### Step 2: Create `.pr_agent.toml`

Place `.pr_agent.toml` in the repository root. Tailor the `extra_instructions` based on the detected project stack.

#### Example: Native Android & Kotlin (`.pr_agent.toml`)
```toml
[pr_reviewer]
extra_instructions = """
You are a strict Senior Android & Kotlin Lead Developer reviewing a Pull Request for a native Android application (Jetpack Compose, Hilt, Room, Coroutines/Flow, Navigation 3). Review this PR using the following rules:

1. Threading & Coroutines: Flag any UI-blocking work on the Main Thread or improper use of `runBlocking`. Ensure Coroutines use correct dispatchers (`Dispatchers.IO` for Network/DB, `Dispatchers.Default` for CPU-heavy tasks) and are bound to appropriate scopes (`viewModelScope`, `lifecycleScope`). Collect flows safely using `collectAsStateWithLifecycle()` in Compose.
2. Jetpack Compose & UI Performance: Ensure composables follow best practices (state hoisting, avoiding passing ViewModels into child composables, proper key usage in `remember`, `LaunchedEffect`, `LazyColumn`/`LazyRow`, and using `derivedStateOf` for calculated states). Flag unnecessary recompositions or missing `@Stable`/`@Immutable` annotations on complex UI models where relevant.
3. Architecture & Dependency Injection: Verify proper MVVM / Clean Architecture boundaries (UI -> ViewModel -> Repository -> Service/DAO). Ensure Hilt modules and injections follow single-responsibility principles and use proper scopes (`@Singleton`, `@ViewModelScoped`).
4. Security & Privacy: Flag any hardcoded secrets, tokens, API keys, or unencrypted storage of sensitive user data. Ensure sensitive values use the secrets obfuscator or BuildConfig/DataStore safely.
5. Resource & Memory Leaks: Ensure Context references (Activity/Fragment) are never retained inside ViewModels, Singletons, or static references. Ensure resources (listeners, audio recorders, C++ native allocations) are cleaned up properly.
6. Tone & Feedback Format: Be concise, constructive, and provide exact idiomatic Kotlin code replacements for any issues found.
"""

[pr_description]
generate_title_and_description = true

[config]
ignore_pr_title = ["^Bump .*", "^Merge .*", "^Auto-generated .*", "^chore\\(deps\\):.*"]
ignore_pr_files = [
    "*.lock",
    "gradlew",
    "gradlew.bat",
    "gradle/verification-metadata.xml",
    "proguard-rules.pro",
    "schemas/**",
    "*.png",
    "*.json",
    "*.jpg",
    "*.jpeg",
    "*.svg",
    "*.webp",
    "*.gif",
    "*.jar"
]
```

### Step 3: Create or Merge `bitbucket-pipelines.yml`

Check if `bitbucket-pipelines.yml` already exists:
1. **If it doesn't exist**: Create a clean `bitbucket-pipelines.yml` using the template below.
2. **If it already exists**: Add the `pull-requests` block under `pipelines:` without overwriting existing build/deploy branches (`branches:`, `custom:`, etc.).

#### Pipeline Configuration:
```yaml
pipelines:
  pull-requests:
    '**': 
      - step:
          name: 🤖 Gemini PR Review (Qodo PR-Agent)
          image: docker:latest
          caches:
            - docker
          services:
            - docker
          script:
            # 1. Only run PR review when targeting specific branches (cost-saving)
            - |
              if [ "$BITBUCKET_PR_DESTINATION_BRANCH" != "main" ] && [ "$BITBUCKET_PR_DESTINATION_BRANCH" != "develop" ] && [ "$BITBUCKET_PR_DESTINATION_BRANCH" != "master" ]; then
                echo "Skipping AI review. PR is not targeting main, develop, or master."
                exit 0
              fi
            
            # 2. Pull the official open-source PR-Agent image (cached)
            - docker pull pragent/pr-agent:latest
            
            # 3. Run PR-Agent natively using Gemini via Google AI Studio with retry logic
            - |
              MAX_RETRIES=3
              RETRY_DELAY=120
              for i in $(seq 1 $MAX_RETRIES); do
                echo "Attempt $i/$MAX_RETRIES to run PR-Agent..."
                if docker run --rm \
                  -v "$(pwd)/.pr_agent.toml:/app/.pr_agent.toml" \
                  -e GOOGLE_AI_STUDIO.GEMINI_API_KEY="$GEMINI_API_KEY" \
                  -e BITBUCKET.BEARER_TOKEN="$BITBUCKET_BEARER_TOKEN" \
                  -e CONFIG.GIT_PROVIDER="bitbucket" \
                  -e CONFIG.MODEL="gemini/gemini-2.5-flash" \
                  -e CONFIG.FALLBACK_MODELS="gemini/gemini-2.5-pro" \
                  -e CONFIG.CUSTOM_MODEL_MAX_TOKENS=1048576 \
                  pragent/pr-agent:latest --pr_url="https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/pull-requests/$BITBUCKET_PR_ID" review; then
                  echo "PR review completed successfully."
                  exit 0
                else
                  EXIT_CODE=$?
                  echo "PR-Agent failed with exit code $EXIT_CODE."
                  if [ $i -lt $MAX_RETRIES ]; then
                    echo "Waiting $RETRY_DELAY seconds before retrying..."
                    sleep $RETRY_DELAY
                  else
                    echo "Max retries reached. Failing the pipeline."
                    exit $EXIT_CODE
                  fi
                fi
              done
```

> **Note on Branch Filtering**: Adjust `"main"`, `"develop"`, and `"master"` in the script if the repository uses different main branches (e.g. `"release/*"`, etc.).

---

### Step 4: Configure Bitbucket Repository Variables

Prompt the user to ensure the following two **Secured Repository Variables** are added in Bitbucket:
Path: **Repository Settings > Pipelines > Repository variables**

| Variable Name | Description | Secured | Scope / Note |
|---|---|---|---|
| `GEMINI_API_KEY` | Google AI Studio Gemini API Key | ✅ Yes | Free or Paid tier key from [Google AI Studio](https://aistudio.google.com/) |
| `BITBUCKET_BEARER_TOKEN` | Bitbucket HTTP Access Token | ✅ Yes | Repository Access Token or Workspace Access Token with required scopes |

#### Creating the Bitbucket Access Token:
1. Go to **Repository Settings > Security > Access tokens** (or **Workspace settings > Access tokens**).
2. Click **Create repository access token**.
3. Name: `PRAgent-Token`.
4. Permissions (Scopes):
   - **Pull requests**: `Read` and `Write` *(required to read diffs and post review comments)*.
   - **Repositories**: `Read` *(recommended)*.
5. Copy the generated token value and save it in **Pipelines > Repository variables** as `BITBUCKET_BEARER_TOKEN`.

---

### Step 5: Verification & Testing

1. Validate YAML syntax for `bitbucket-pipelines.yml`:
   Ensure indentation is correct and the `services: [docker]` definition is present.
2. Commit the new files:
   ```bash
   git add bitbucket-pipelines.yml .pr_agent.toml
   git commit -m "ci: add Bitbucket pipeline with Qodo PR-Agent for automated PR reviews"
   ```
3. Push to remote and open a draft pull request targeting `develop` or `main`.
4. Observe the pipeline execution in Bitbucket:
   - Checks destination branch match.
   - Pulls `pragent/pr-agent:latest`.
   - Performs code review using Gemini.
   - Posts a structured review with summaries, questions, and inline code suggestions directly onto the Bitbucket Pull Request.

---

## Critical Rules & Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| **`docker: Cannot connect to the Docker daemon`** | Missing Docker service in Bitbucket step | Ensure `services: - docker` is defined under the step. |
| **`403 Forbidden` or failed to post comment** | `BITBUCKET_BEARER_TOKEN` lacks write permission | Ensure the token has `Pull requests: Write` permissions in Bitbucket Access Tokens. |
| **`Invalid model name or 404 on Gemini`** | Model alias mismatch | Use `gemini/gemini-3.5-flash` or `gemini/gemini-2.5-pro` with `GOOGLE_AI_STUDIO.GEMINI_API_KEY`. PR-Agent uses LiteLLM internally. |
| **Docker pull fails for image** | Using wrong registry name | Always use `pragent/pr-agent:latest` (the official public Docker image). |
| **Review skipped unexpectedly** | Destination branch condition | Verify `$BITBUCKET_PR_DESTINATION_BRANCH` matches the target branch in the pipeline script. |
| **Token context limit exceeded on huge PRs** | Very large diffs | `CONFIG.CUSTOM_MODEL_MAX_TOKENS=1048576` enables large context window for Gemini. Add large or generated files to `ignore_pr_files` in `.pr_agent.toml`. |
