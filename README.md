# 🧠 Antigravity Agent Skills Repository

A centralized collection of custom agent skills for Google Antigravity / Gemini CLI & IDE.

---

## 📦 Included Skills

| Skill | Description | Target / Use Case |
|---|---|---|
| **[`android-deploy`](./android-deploy/SKILL.md)** | Automates version bumping, Fastlane APK builds, Google Drive uploads, changelog extraction, and rich Slack Block Kit notifications | Android Releases & CI/CD |
| **[`android-build-speed`](./android-build-speed/SKILL.md)** | Deep Gradle build optimization: activeVariant filtering, G1GC tuning, AGP 9+ compiler options, cache reuse | Android Build Performance |
| **[`clickup-logger`](./clickup-logger/SKILL.md)** | Submits and updates time tracking entries on ClickUp tasks via CLI | Productivity & Time Tracking |
| **[`debroid-cli`](./debroid-cli/SKILL.md)** | Headless Android JDWP debugging, runtime inspection, breakpoints, and live state evaluation | Android Debugging |
| **[`git-history-rewrite`](./git-history-rewrite/SKILL.md)** | Safely rewrites Git commit author and email history across branches and tags | Git Repository Maintenance |
| **[`ios-code-audit`](./ios-code-audit/SKILL.md)** | Senior iOS architecture, security, performance, and SwiftUI production-readiness auditor | iOS Code Review & Quality |

---

## 🚀 Setup on a New Machine

To install all of these skills on a new Mac or workstation:

```bash
# Clone directly into Antigravity skills directory
git clone https://github.com/tapan-xenabler/agent_skills.git ~/.gemini/config/skills
```

All skills will immediately be recognized and ready to use in your Antigravity agent sessions.
