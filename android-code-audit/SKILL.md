---
name: android-code-audit
description: Deep-dive Android architecture, performance, and security audit generator with a Xenabler-branded HTML dashboard.
---

# Android Code Audit & Dashboard Generator

This skill performs a comprehensive, deep-dive architectural and performance audit on Android codebases (specifically checking for Android 15/16/17 compliance, LiveData memory leaks, and heavy UI inflation) and generates a beautifully styled, interactive HTML dashboard using the official Xenabler brand colors.

## Triggers
Activate this skill when the user asks to:
- "Run a code audit on this Android project"
- "Generate an Android audit report"
- "Audit my Android app and generate the HTML dashboard"

## Execution Steps

### 1. Perform the Audit
Read the rules and guidelines from the audit prompt:
`view_file ~/.gemini/config/skills/android-code-audit/prompt.md`

Use standard bash tools (`grep`, `find`) or `graft` to scan the project for the issues defined in the prompt. Create a new directory called `code audit/` in the project root and write the following markdown files:
- `Executive-Code-Review.md`
- `Project-Inventory-and-Build-Verification.md`
- `Architecture-and-Modernization-Review.md`
- `Security-and-Privacy-Review.md`
- `Performance-Memory-and-Battery-Review.md`
- `UI-UX-Design-System-and-Accessibility-Review.md`
- `Testing-Strategy.md`
- `Release-Readiness-Review.md`
- `Remediation-Roadmap.md`
- `Detailed-Findings.md`
- `Severity-Summary.md`
- `Module-File-Risk-Summary.md`
- `Release-Blocker-Checklist.md`
- `Unknowns-and-Validation-Blockers.md`
- `Pull-Request-Checklist.md`
- `findings.json`

### 2. Generate the Xenabler HTML Dashboard
Once all markdown files are saved in the `code audit/` folder, run the global Ruby generator script to parse the markdown and build the Xenabler-branded interactive HTML report.

First, copy the ruby script to the project workspace:
```bash
cp ~/.gemini/config/skills/android-code-audit/generate_report.rb ./scratch/generate_report.rb
ruby ./scratch/generate_report.rb
```

### 3. Finalize
Provide the user with a local `file://` link to `code audit/code_audit_report.html` and summarize the top 3 most critical findings.
