# 🧠 Antigravity Agent Skills Repository

A centralized collection of custom agent skills for Google Antigravity / Gemini CLI & IDE.

---

## 📦 Included Skills

| Skill | Description | Target / Use Case |
|---|---|---|
| **[`android-standards`](./android-standards/SKILL.md)** | Bootstraps, reverse-engineers, audits, and evolves 4 foundational specs (Architecture, Security, Design, Requirement), pluggable analytics, and CI/CD pipelines for Native Android | Android Architecture & Standards Engine |
| **[`android-deploy`](./android-deploy/SKILL.md)** | Automates version bumping, Fastlane APK builds, Google Drive uploads, changelog extraction, and rich Slack Block Kit notifications | Android Releases & CI/CD |
| **[`android-build-speed`](./android-build-speed/SKILL.md)** | Deep Gradle build optimization: activeVariant filtering, G1GC tuning, AGP 9+ compiler options, cache reuse | Android Build Performance |
| **[`android-code-audit`](./android-code-audit/SKILL.md)** | Deep-dive Android architecture, performance, and security audit generator with Xenabler-branded dashboard | Android Architecture & Security Audit |
| **[`graphify`](./graphify/SKILL.md)** | Converts any repository/docs into a persistent queryable knowledge graph with community detection and visualizer | Codebase Knowledge Graph & Topology |
| **[`clickup-logger`](./clickup-logger/SKILL.md)** | Submits and updates time tracking entries on ClickUp tasks via CLI | Productivity & Time Tracking |
| **[`bitbucket-pr-agent`](./bitbucket-pr-agent/SKILL.md)** | Sets up Bitbucket Pipelines with Qodo PR-Agent and Google Gemini for automated AI pull request reviews | CI/CD & Automated Code Review |
| **[`debroid-cli`](./debroid-cli/SKILL.md)** | Headless Android JDWP debugging, runtime inspection, breakpoints, and live state evaluation | Android Debugging |
| **[`git-history-rewrite`](./git-history-rewrite/SKILL.md)** | Safely rewrites Git commit author and email history across branches and tags | Git Repository Maintenance |
| **[`ios-code-audit`](./ios-code-audit/SKILL.md)** | Senior iOS architecture, security, performance, and SwiftUI production-readiness auditor | iOS Code Review & Quality |

---

## 📜 Shared Agent Rules (`rules/`)

Reusable agent rules that can be placed in `.agents/rules/` or referenced globally:

| Rule | Description |
|---|---|
| **[`android-standards.md`](./rules/android-standards.md)** | Enforces the 4-pillar native Android standards (Clean Architecture, MASVS Security, WCAG2Mobile Design, and Requirement specs) |
| **[`graphify-graft-context.md`](./rules/graphify-graft-context.md)** | Auto-bootstrap and token-saving orchestrator for Graphify and Graft AST indexing |


---

## 🚀 Setup on a New Machine

To install all of these skills on a new Mac or workstation:

```bash
# Clone directly into Antigravity skills directory
git clone https://github.com/tapan-xenabler/agent_skills.git ~/.gemini/config/skills
```

All skills will immediately be recognized and ready to use in your Antigravity agent sessions.
