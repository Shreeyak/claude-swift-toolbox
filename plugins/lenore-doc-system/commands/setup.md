---
description: Detect or install the Lenore doc system in this repo (propose-then-apply)
argument-hint: "[--write]"
allowed-tools: Bash(git:*), Bash(chmod:*), Bash(mkdir:*), Bash(ln:*), Read, Write, Edit, Glob, Grep
---

Set up the Lenore doc system (see the `doc-system` skill for the full
doctrine) in the current repository. This is **propose-then-apply**: show
the plan, apply only after the user confirms.

## 1. Detect current state

- `grep -l "docs-system:" CLAUDE.md` (or its absence) tells you whether the
  repo already has the system installed, and at which tier.
- If found: this is an **upgrade**. Diff the repo's copies of
  `.githooks/pre-commit`, `.githooks/pre-push`, `scripts/doc-status.sh`,
  `scripts/browse.py`, `docs/CLAUDE.md` against this plugin's
  `templates/` — propose replacing any that differ, and report the
  diffs. Do not touch `docs/journal/`, `docs/notes/`, or other content.
- If not found: this is a **fresh install** — go to step 2.

## 2. Ask the tier (fresh install only)

Ask the user: Tier 1 (real project — journal/notes/reference/tasks/bugs
split, openspec, experiments, desk) or Tier 0 (small/experiment repo —
`docs/log/` only, no tracking machinery). Default to Tier 1 unless the repo
is clearly a weekend/experiment repo, and say why you're defaulting that
way.

## 3. Build the proposal

**Tier 1:**

- Create `docs/{journal,notes,reference,tasks,bugs}/` and `tmp/` (each with
  a `.gitkeep` if needed for an empty dir to exist, except `tmp/` which is
  gitignored wholesale).
- Copy `templates/githooks/{pre-commit,pre-push}` to `.githooks/`, then
  `chmod +x` both.
- Copy `templates/scripts/{browse.py,doc-status.sh,docs-search.py}` to
  `scripts/`, then `chmod +x doc-status.sh` (`browse.py`/`docs-search.py`
  are invoked via `uv run`, executable bit optional but harmless to set).
  Mention to the user that `docs-search.py` (local semantic search, Apple
  Silicon only) is optional — its setup and troubleshooting live in
  `references/semantic-search-setup.md` in the `doc-system` skill, install
  only once grep starts missing things.
- Copy `templates/docs-CLAUDE.md` to `docs/CLAUDE.md`.
- `git config core.hooksPath .githooks` (repo-local, once).
- Symlink `AGENTS.md -> CLAUDE.md` at repo root, and `docs/AGENTS.md ->
  CLAUDE.md` beside `docs/CLAUDE.md`.
- Append the block from `skills/doc-system/references/rules-tier1.md`
  verbatim into the repo's `CLAUDE.md`, followed by a line:
  `docs-system: lenore-v1 (tier 1)`
- Append `templates/gitignore-snippet` to `.gitignore` (create it if
  absent).
- Register `scripts/doc-status.sh` as a `SessionStart` hook in
  `.claude/settings.json` — **merge into the existing hooks array, never
  overwrite the file**. If a Codex config exists in this repo, note that
  the user should wire the same script into Codex's session-start
  equivalent (this command does not touch Codex config).

**Tier 0:**

- Create `docs/log/`.
- Append the block from `skills/doc-system/references/rules-tier0.md`
  verbatim into `CLAUDE.md`.
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
diffs — the migration steps from `doc-system` skill §11 / the artifact's
§11:

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
has confirmed the diff. This mirrors §04's "deleting or pruning requires
showing the diff" rule.

## 6. Close out

Tell the user to run `/code-intel:setup`-style follow-up isn't needed here;
just point them at `uv run scripts/browse.py` to confirm the install looks
right, and remind them the pre-commit/pre-push hooks are now live for every
future commit and push in this clone.
