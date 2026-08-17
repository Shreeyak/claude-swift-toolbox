---
description: Detect or install the Lenore doc system in this repo (propose-then-apply)
argument-hint: "[--write]"
allowed-tools: Bash(git:*), Bash(chmod:*), Bash(mkdir:*), Bash(ln:*), Bash(test:*), Read, Write, Edit, Glob, Grep
---

Set up the Lenore doc system (see the `doc-system` skill for the full
doctrine) in the current repository. This is **propose-then-apply**: show
the plan, apply only after the user confirms.

## 1. Detect current state

- Detect an existing install by **any** of these signals — treat the repo
  as installed if at least one holds; never classify as fresh while any is
  present (blind-appending the rules block onto a repo that already has
  rules is the single most damaging failure mode):
  - `.githooks/pre-commit` exists **and** contains a lenore signature
    (grep it for `denied_names`) — a bare `.githooks/pre-commit` without
    that signature is someone else's hook framework: stop and ask, don't
    assume either way;
  - `docs/journal/` or `docs/log/` exists;
  - `CLAUDE.md` contains a `docs-system:` line or a line beginning with
    `<!-- lenore:rules:start` (a partial install — rules appended but
    machinery never created — must land in the upgrade path, not fresh).
  The `docs-system:` marker (or the start-marker's tier annotation) tells
  you the tier; if the two disagree, ask the user which is right.
- If artifacts are found: this is an **upgrade**. Diff the repo's copies of
  `.githooks/pre-commit`, `.githooks/pre-push`, `.githooks/pre-merge-commit`,
  `.githooks/commit-msg`, `scripts/doc-status.sh`, `scripts/browse.py`,
  `scripts/docs-search.py`, `scripts/lenore-docs.py`,
  `docs/CLAUDE.md` against this plugin's `templates/` — propose replacing
  any that differ, and report the diffs. Do not touch `docs/journal/`,
  `docs/notes/`, or other content.
  For the rules block in root `CLAUDE.md`: the managed span starts at the
  line **beginning with** `<!-- lenore:rules:start` (the shipped marker
  carries a tier annotation and warning text after that prefix — match the
  prefix, never the full literal) and runs through the first subsequent
  `<!-- lenore:rules:end -->` line, inclusive. If the span is present,
  replace exactly that span with the current tier's rules block, showing a
  diff first for any local edits inside it; everything outside the span —
  project-specific rules, qualifiers, exceptions — is never touched.
  Edge cases: a start marker with **no** end marker is a damaged span —
  never replace start-to-end-of-file; fall through to the legacy merge
  path below. **Multiple** start markers (a legacy double-append): replace
  the first span and include the deletion of the later span(s) in the
  shown diff — never silently leave a stale second block. If the repo has
  rules but no markers (legacy), do NOT append: show the user the current
  rules next to the template block, propose a merge that wraps the managed
  portion in the markers while keeping every project-specific qualifier
  outside them, and apply only what they confirm.
- If no artifacts are found: this is a **fresh install** — go to step 2.
- **Activation check — always run, on both upgrade and fresh install.**
  The `docs-system:` marker being present in `CLAUDE.md` only means the
  system was installed *once*; it does not mean *this clone* is active
  (`core.hooksPath` is local config that a `git clone` never carries over,
  and gitignored directories vanish on clone too). So regardless of which
  branch above you took, always also verify and repair:
  - `git config core.hooksPath` is `.githooks` (set it if missing or
    unset — see the "existing hooks" note below if it's set to something
    else).
  - `.githooks/pre-commit`, `.githooks/pre-push`, `.githooks/pre-merge-commit`,
    `.githooks/commit-msg`
    exist and are executable (`chmod +x` if not, restore from `templates/`
    if missing).
  - `AGENTS.md -> CLAUDE.md` exists at repo root and `docs/AGENTS.md ->
    CLAUDE.md` exists beside `docs/CLAUDE.md` (Tier 1) — recreate any
    missing symlink.
  - `docs/desk/` and `tmp/` exist (Tier 1) — both are gitignored and so
    do not survive a clone; recreate if missing.
  - The `SessionStart` hook registration for `scripts/doc-status.sh` is
    present in `.claude/settings.json` — re-add if missing.
  Report what was found broken and repaired, even if nothing else changed.

## 2. Ask the tier (fresh install only)

Ask the user: Tier 1 (real project — journal/notes/reference/tasks/bugs
split, openspec, experiments, desk) or Tier 0 (small/experiment repo —
`docs/log/` only, no tracking machinery). Default to Tier 1 unless the repo
is clearly a weekend/experiment repo, and say why you're defaulting that
way.

## 3. Build the proposal

**Existing hooks check (both tiers, before touching hooks):** if
`core.hooksPath` is already set to something other than `.githooks`, or
`.githooks/` already exists with hook files this plugin didn't put there,
**stop and ask the user how to chain** (e.g. wrap the existing hook to also
exec this plugin's, or vice versa) rather than silently overwriting.

**Tier 1:**

- Create `docs/{journal,notes,reference,tasks,bugs}/`, `docs/desk/`, and
  `tmp/` (each doc subdir gets a `.gitkeep` if needed for an empty dir to
  exist, except `tmp/` which is gitignored wholesale and `docs/desk/`
  which is also gitignored — see gitignore-snippet).
- Create `docs/tasks/project.md` with `## Next` and `## Someday` headings
  if it does not already exist.
- Copy `templates/githooks/{pre-commit,pre-push,pre-merge-commit,commit-msg}`
  to `.githooks/`, then `chmod +x` all four.
- Copy `templates/scripts/{browse.py,doc-status.sh,docs-search.py,lenore-docs.py}`
  to `scripts/`, then `chmod +x doc-status.sh lenore-docs.py` (`browse.py`/`docs-search.py`
  are invoked via `uv run`, executable bit optional but harmless to set).
  Mention to the user that `docs-search.py` (local semantic search, Apple
  Silicon only) is optional — its setup and troubleshooting live in
  `references/semantic-search-setup.md` in the `doc-system` skill, install
  only once grep starts missing things.
- Copy `templates/docs-CLAUDE.md` to `docs/CLAUDE.md`.
- `git config core.hooksPath .githooks` (repo-local, once).
- Symlink `AGENTS.md -> CLAUDE.md` at repo root, and `docs/AGENTS.md ->
  CLAUDE.md` beside `docs/CLAUDE.md` — skip creating a symlink that
  already points at the right target; if `AGENTS.md` exists and is
  *not* that symlink, stop and ask before overwriting it.
- Append the block from `skills/doc-system/references/rules-tier1.md`
  verbatim into the repo's `CLAUDE.md` (the block ships wrapped in
  `<!-- lenore:rules:start -->` / `<!-- lenore:rules:end -->` markers —
  keep them; they are what makes future upgrades surgical), followed by a
  line: `docs-system: lenore-v1 (tier 1)` — **idempotent**: skip the
  append if the start marker or the `docs-system:` line is already
  present. Even on a fresh install, if `CLAUDE.md` already contains
  doc-related rules, show the user what the block would add next to what
  exists rather than appending blind — a project qualifier (an exception,
  a local naming rule, a "specs don't exist yet" caveat) must survive
  outside the managed span.
- Append `templates/gitignore-snippet` to `.gitignore` (create it if
  absent) — **idempotent**: grep for the snippet's marker line first and
  skip if already present.
- No Claude Code hook registration is needed for the status line: the
  plugin itself ships a `SessionStart` hook (no matcher, so it fires on
  startup, resume, clear, *and compact* — long auto-compacting sessions
  re-see the status line at every compaction) that runs the repo's
  committed `scripts/doc-status.sh` when present and exits silently
  elsewhere. **Upgrade path:** if an earlier install added a
  `doc-status.sh` `SessionStart` entry to this repo's
  `.claude/settings.json`, propose removing it — otherwise the status
  line prints twice per session start.
- Nothing to install for the advisory drift lint: `doc-lint.sh` runs as a
  plugin-level PreToolUse hook on Bash (from the plugin's `hooks/hooks.json`)
  in every repo where this plugin is enabled. It acts only on `git commit`
  commands that touch docs judgment-rule files or experiment run records,
  batching them (plus the affected experiments' READMEs as context, to catch
  a run contradicting a stale verdict) into one cheap Haiku check; violations block that one commit attempt with the reasons,
  and re-running the same commit unchanged proceeds (warn-once). Self-gated
  on `docs/CLAUDE.md` existing; disable with `LENORE_NO_LINT=1`.
  If a Codex config exists in this repo, install `templates/codex-hooks.json`
  as `.codex/hooks.json` (merge, don't overwrite): it registers
  `scripts/doc-status.sh` as Codex's `SessionStart` hook equivalent. (Codex requires per-repo hooks to be trusted: the first interactive `codex` session in the repo prompts to trust the hook and records a `trusted_hash` in `~/.codex/config.toml`; until then, non-interactive `codex exec` runs silently skip it).

**Tier 0:**

- Create `docs/log/`, with a `.gitkeep` inside it so the directory
  survives a fresh clone (it's otherwise empty and untracked-dir-vanishes
  on clone).
- Symlink `AGENTS.md -> CLAUDE.md` at repo root (Codex parity) — same
  existing-file check as Tier 1 above.
- Append the block from `skills/doc-system/references/rules-tier0.md`
  verbatim into `CLAUDE.md` — idempotent (grep for the marker first),
  same as Tier 1.
- No hooks, no scripts, no tasks/bugs/reference machinery.

## 4. Show the proposal, then apply only on confirmation

Print every file to be created/modified and the diff for each modified
file (especially the `CLAUDE.md` append and any `.gitignore` change).
**Do not write anything until the user confirms.** Once confirmed, apply
in the order above so a failure partway through leaves a legible partial
state (hooks/scripts before the `CLAUDE.md` marker line, so a re-run can
detect "no marker yet" and resume).

## 5. Offer migration of legacy files (Tier 1 only, confirmable per item)

If any of these exist, propose — as separate, individually confirmable
diffs — the migration steps:

- `decisions.md` → split: still-true constraints into `CLAUDE.md`/specs;
  the rest becomes dated `docs/journal/` files (dated from git blame/log),
  IDs and supersession markers stripped.
- `state.md` → task content into `docs/tasks/project.md`; architecture
  content discarded (offer to generate a fresh dated architecture note
  instead); history backfilled as journal files for the 5-10 pivotal
  moments only — ask the user which those are, don't guess.
- `pending.md` / `TASKS.md` / `user-to-do.md` → sorted into
  `docs/tasks/project.md` under Next/Someday.
- Old reports/explorations/handoffs → `docs/notes/`, date-prefixed from
  git history.
- `experiments/*/README.md` missing front-matter → propose adding
  `status`/`verdict`/`concluded` fields.

Never delete the legacy file until its replacement is written and the user
has confirmed the diff. This mirrors the standing rule that "deleting or pruning requires
showing the diff" rule.

## 6. Close out

No follow-up command is needed. Point the user at `uv run scripts/browse.py` to confirm the install looks
right, and remind them the pre-commit/pre-push hooks are now live for every
future commit and push in this clone.
