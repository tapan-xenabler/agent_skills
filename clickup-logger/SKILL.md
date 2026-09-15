---
name: clickup-logger
description: >-
  Use this skill when the user asks to log, add, or update time entries for tasks in ClickUp.
  It provides a reusable CLI tool to submit time entries with parsed duration strings.
---

# ClickUp Time Logger Skill

This skill allows the agent to easily log time entries in ClickUp for one or multiple tasks on any given date. It utilizes a reusable Python script to communicate directly with ClickUp's REST API.

## Helper Script

The core logic is implemented in the following script:
- Reusable Python CLI script: [`clickup_time_logger.py`](./scripts/clickup_time_logger.py)

## Execution Instructions

The script reads the ClickUp API key from the `CLICKUP_API_KEY` environment variable.

### 1. Single Entry Mode
To log a single task entry:
```bash
python3 /Users/tapangohil/.gemini/config/skills/clickup-logger/scripts/clickup_time_logger.py \
  --date "YYYY-MM-DD" \
  --tid "<task_id>" \
  --desc "<description>" \
  --duration "<duration>"
```
*Example:*
```bash
python3 /Users/tapangohil/.gemini/config/skills/clickup-logger/scripts/clickup_time_logger.py \
  --date "2026-08-26" \
  --tid "86d44znpy" \
  --desc "location permission related changes" \
  --duration "2h 30m"
```

### 2. Bulk/Multi-Entry Mode
To log multiple entries for a single day at once, use the `--file` or `--json` option:

Using `--file` (recommended for predictable, auto-approvable execution):
```bash
python3 /Users/tapangohil/.gemini/config/skills/clickup-logger/scripts/clickup_time_logger.py \
  --file /path/to/entries.json
```

Using `--json`:
```bash
python3 /Users/tapangohil/.gemini/config/skills/clickup-logger/scripts/clickup_time_logger.py \
  --json '{
    "date": "YYYY-MM-DD",
    "entries": [
      {
        "tid": "<task_id_1>",
        "description": "<desc_1>",
        "duration": "<duration_1>"
      },
      {
        "tid": "<task_id_2>",
        "description": "<desc_2>",
        "duration": "<duration_2>"
      }
    ]
  }'
```

### 3. Duration Format
The script dynamically parses durations. Supported formats include:
- `2h`, `2.5hr`, `2 hours`
- `30m`, `30 min`, `30 minutes`
- `1h 30m`, `1 hour 30 mins`

## Validation

A successful run will print the returned ClickUp Time Entry ID(s) and exit with code 0:
```text
Success! Time Entry ID: 5240976794715019931
Completed: 1/1 entries logged successfully.
```
