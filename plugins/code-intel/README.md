# `code-intel`

Routing knowledge for code navigation and search, packaged as a skill, three
hooks, a setup command and a doctor.

```bash
claude plugin install code-intel@claude-swift-toolbox
claude plugin install code-intel-lsp@claude-swift-toolbox   # the language servers
```

## The problem

Complementary code-intelligence tools exist — language servers, serena, semantic
code graphs, `ast-grep`, `semgrep`, per-language linters and type checkers, and
plain `grep` — but the knowledge of *when to use which* is scattered. Agents
habitually skip the semantic tools and reach for `grep` even when `grep` is the
wrong instrument for the question, then act on an answer that over-matched
comments and unrelated same-named symbols.

## Honest scope

The **routing table and trust calibration are language-agnostic** and apply
anywhere serena or a language server has a backend — roughly fifty languages.

**Deep setup guides ship for six profiles**: TypeScript/JavaScript, Python, C++
(CMake, colcon-style workspaces, and a short cross-compile/embedded section —
a section, not a promise of full embedded coverage), Swift, and mixed-language
boundaries (Python↔C++, Swift↔C++).

**Everything else** — Go, Rust, JVM, .NET, Ruby, PHP and the rest — gets the
generic path: serena plus the routing table plus `setup-generic.md`, which says
how to adapt. That is a real path, not a fallback apology, but it is not a
per-stack guide. This plugin does not claim universality.

**Non-goals**: shipping tool binaries; replacing `grep` (it keeps its lanes —
constants, string literals, prose, inventory sweeps, generated artifacts,
macros, and completeness cross-checks); auto-running self-modifying installers.

**Platform: macOS and Linux.** All scripts are bash. Windows is untested and
unsupported.

## What is in it

### The router skill

Triggers on explicit code-navigation intent only — find callers, references,
usages, where something is defined, all implementations, rename a symbol,
concept search. Deliberately **not** on "explain the architecture", "what does
this change affect", or "unfamiliar repo": those phrasings would pull the skill
into most sessions, and its content would then persist in context for the whole
of them.

It routes by question, and it insists every answer name its **mechanism class**:

- **Semantic** (LSP, serena) — exact resolution within an *indexed build graph*.
  A partial or stale index silently under-reports: a confident empty answer, not
  an error. Reflection, DI, codegen, template instantiation, conditional
  compilation and runtime dispatch are invisible or approximate.
- **Name-match** (tree-sitter graphs) — no build needed; misses renamed, mangled
  and aliased symbols; cannot disambiguate same-named overloads; preprocessor-blind.
- **Textual** (`grep`, `ast-grep`) — complete over the text scanned, no
  resolution, over-matches.

All three are fallible in different directions, which is why a semantic answer
that feeds a refactor gets a textual completeness cross-check, and a textual
answer gets semantic disambiguation when the name is common.

### Three behaviour layers, each honest about its causal power

| Layer | When it fires | What it can actually cause |
|---|---|---|
| **SessionStart status** | session begin and resume | At most two lines of *dynamic* facts — per-tool state, and the fix for anything unsatisfiable. Silent when there is nothing actionable. Carries no static routing text: that would be re-emitted every resume and would train the model to skip it. |
| **UserPromptSubmit intent router** | the user's prompt is an explicit navigation question **and** a semantic tool is configured | One line, **before the model picks a tool** — the only pre-decision moment a hook gets. |
| **PostToolUse grep nudge** | a text search whose pattern is a bare identifier, twice per session at most | **Corrective, not preventive.** The search has already run; the note arrives alongside its output. Deliberately *not* PreToolUse: that event carries no `additionalContext` (the note would be dropped) and its `permissionDecision: "allow"` bypasses the permission system rather than merely not blocking — a nudge must never auto-approve what it comments on. |

All three are pure bash, fail-open (any error exits 0 silently), touch no
network, and shell out to no interpreter — a missing `python3` must never turn a
status line into a hook error.

### `/code-intel:setup`

**Propose-then-apply.** The default run detects the stack, prints the proposal
with a diff of every file it would change, and stops. `--write` applies it.
Writes are atomic with a single `.bak`; only keys the manifest owns are touched;
malformed existing JSON is a **refusal**, never an auto-repair. Missing binaries
produce install one-liners, never an install. The accepted proposal is recorded
in `.code-intel.json`, which makes re-runs true no-ops.

### `/code-intel:doctor`

Walks the state model **binary → started → initialized → workspace → probe**,
with a fix for each rung. The last rung is run by the agent, not the script:
bash cannot speak LSP, so nothing in `scripts/` can distinguish a working server
from one that starts cleanly and answers wrongly. `clangd` with no compile
database is exactly that case. The doctor says so rather than reporting green.

## References

Loaded on demand by the skill, in `skills/code-intel/references/`:
`tools-catalog.md`, `setup-typescript.md`, `setup-python.md`, `setup-cpp.md`,
`setup-swift.md`, `setup-mixed-language.md`, `setup-generic.md`, `mcp-wiring.md`.
