# Cross-Project Graphify & Graft Context Rule

This is a mandatory system-wide guardrail. To minimize agent loops, avoid token-window explosion, and increase execution speed across all workspaces, you are provided with two localized token-saving context tools: **Graphify** (Global Topology Explorer) and **Graft** (Tactical Code Scalpel).

## 🚀 STEP 1: ON-DEMAND AUTO-BOOTSTRAP (Pre-Flight Project Check)
Whenever a prompt is initialized in a new or unindexed repository workspace, check the filesystem boundaries immediately. If the index folders are missing, run these setups silently before attempting any code actions:

1. **Graphify Initialization Check:** 
   - Look for the `graphify-out/` folder in the current project root.
   - If missing: Execute `uv tool install graphifyy` (or `pipx install graphifyy` if uv is unavailable) to ensure the engine is globally ready. Then execute `graphify antigravity install && graphify .` to run local AST-indexing.
2. **Graft Initialization Check:**
   - Look for the `graft/` folder in the current project root.
   - If missing: Execute `npm install -g @nanonets/graft` to ensure the tool is globally ready. Then execute `graft init --agents claude --yes && graft build` to index code skeletons.

## 📡 STEP 2: ORCHESTRATED TOOL ROUTING PROTOCOL
Once the workspace dependencies are mapped, you must route your exploratory actions through the graph engines to conserve tokens:

### 🗺️ Use Graphify For Macro Topology & Context Ingestion
* **Dependency Tracing:** Run `graphify path "ComponentA" "ComponentB"` to map multi-file relationship calls. Never walk file trees manually.
* **Non-Code Requirements:** Route searches regarding architecture sheets, database structures, or technical documentation PDFs through `graphify query "<your question>"`.
* **Syncing Graph Changes:** If files change via git updates, pass `graphify update .` to patch the AST graph locally for $0.

### 🗜️ Use Graft For Micro Code Exploration & Actionable Edits
* **Signature Inspection (The 1/10th Token Rule):** Instead of using full text readers (`cat` or broad view commands) on massive target source files, execute `graft skeleton <path/to/file>` to view function signatures at a fraction of the cost.
* **Blast-Radius Isolation:** Before mutating a module export, class property, or shared utility, invoke `graft callers <symbol>` to verify what else will break.
* **Workspace Memory Layer:** Execute `graft trail pull` to inherit any system rules or structural corrections configured by the user in previous turns.

## 🚫 CRITICAL CONSTRAINTS
* Do not resort to recursive system commands like `grep -r` or `find .` unless specialized graph methods return empty results.
* Always prioritize structural code representations over pulling heavy implementation bodies into context.
