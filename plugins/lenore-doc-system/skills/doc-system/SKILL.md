---
name: doc-system
description: Rules for writing, filing, and finding documentation in a repo using the Lenore doc system — journal, notes, tasks, bugs, experiments, desk, landing. Invoke before creating or moving any doc file, before landing a branch, or when adopting the system in a new repo.
---

# Lenore doc system

Human-readable edition (rationale, review history):
https://claude.ai/code/artifact/fe938177-22fc-43d6-be6d-842ece97226b

Docs are dated files in the code repo, immutable once committed, written
directly in flow at milestone cadence. Current truth and history are
different substances kept in different places. High-damage rules are
enforced by committed git hooks, not by prose discipline.

## Principles

- **History and current truth are different substances.** Current truth
  lives only in `openspec/specs/`, `CLAUDE.md` invariants, and experiment
  READMEs — committed with the code they describe. Everything else
  (journal, notes, run records) is non-authoritative history: what
  happened and what was believed, never what is true now. Nothing treats
  history as an authority, so it can't ossify into an ADR.
- **Prose has no addresses; links are one-way.** No entry IDs, no
  code/docstrings referencing docs, ever. Cite commit hashes; name dated
  files or experiment folders in plain words. Nothing links back; nothing
  checks links.
- **Many small files, immutable once committed.** One file per journal
  entry, note, run, bug. Unique files never merge-conflict across sessions
  or worktrees. **Immutability begins at commit** — fix typos freely
  before committing; a committed file is history and stays as written.
- **Write direct, in flow, at milestone cadence.** Write to the
  destination file in the same session content surfaces — no inbox, no
  staging, no filing agent. Cadence ties to milestones (phase done,
  experiment concluded, direction changed), never to commits.
- **Rules are enforced by git, or they're advisory.** Committed
  `.githooks/` (pre-commit + pre-merge-commit + pre-push) catch the common
  local write and merge paths once activated in a clone (`core.hooksPath`
  set, hook files executable) — they do not cover web-UI merges, `--no-verify`,
  or a clone where activation hasn't run yet; `/lenore-doc-system:setup`'s
  activation check exists to keep that gap small. Harness hooks carry only
  information (the status line), never rules.
- **Deleting/pruning doc content requires showing the diff; writing new
  content does not.**

## The layout (Tier 1)

`CLAUDE.md` states the tier. Never scaffold Tier 1 unasked; Tier 0 repos
get only `docs/log/` (dated files, journal+notes merged) — see
`references/rules-tier0.md`.

```
CLAUDE.md                    hub: tier, conventions, invariants, doc rules
openspec/
  specs/                     as-built truth — committed atomically with code
  changes/                   in-flight work; archived on landing
docs/
  CLAUDE.md                  formatting details only (entry shapes, front-matter)
  journal/2026-08-15-1432-topic.md    one immutable file per entry
  notes/2026-08-02-topic.md           dated, immutable; line 1 = summary
  reference/ferry-cli-integration.md  named, editable, living how-tos
  desk/                      gitignored, per-worktree symlinks (see doc-classes.md)
  tasks/project.md · branch-<name>.md
  bugs/2026-08-15-topic.md
experiments/                 repo ROOT, not docs/ — code+data+outputs
  <name>/README.md · runs/*.md · src/ · data/ · out/
.githooks/                   pre-commit + pre-push — all rule enforcement
scripts/browse.py · doc-status.sh
tmp/                         gitignored wholesale
```

`docs/` holds only prose (`.md`, `.html`, images) — a pre-commit hook
enforces this. Full per-directory rules: `references/doc-classes.md`
(read when you need the complete rule for journal / notes / reference /
tasks / bugs / experiments' three zones / desk semantics incl.
remove-vs-delete / tmp / scripts / openspec).

## When X happens, do Y

| Trigger | Action |
|---|---|
| Bug noticed (by anyone, any time) | File `docs/bugs/YYYY-MM-DD-topic.md` now — one-line symptom + ≤5 lines. Don't derail current work. Delete it in the fix commit. |
| Openspec phase / task-group completed | Write a journal entry (shape below). |
| Experiment concluded | Flip the README's `status`/`verdict` front-matter, then a journal entry restating the verdict — same session. |
| Direction changed | Journal entry: what we believed / learned / do now. |
| Milestone hit, no change folder (exploratory branch) | One journal entry per concluded work-topic. |
| Status line shows a large gap | One catch-up journal entry (~20 lines) summarizing the arc from `git log` — don't back-fill many. |
| You produce a doc FOR the user | Save it in its normal home (usually `docs/notes/`), symlink it into `docs/desk/` in the same message. |
| User says "put/take X on/off my desk" or "delete X" | Do it in plain words — see `references/doc-classes.md` desk section for remove-vs-delete semantics. |
| Branch is landing or being abandoned | Run `/lenore-doc-system:land`. Never a bare `git merge` into main. |
| Repo has no doc system yet, or needs upgrading | Run `/lenore-doc-system:setup`. |
| Before a proposal/design, or "did we try this before?" | Search `docs/notes/` + experiment READMEs (`scripts/browse.py --plain` or grep) — see `references/routing.md`. |
| Any "where do I find X" question | `references/routing.md` — the question→location table. |
| Concept/vocabulary question over past docs ("did we explore X?") | `scripts/docs-search.py "query"` if `.docs-embeddings/` exists (local jina-v5 embeddings on MLX); else grep + `browse.py --plain` — not set up yet → `references/semantic-search-setup.md`. |

## The journal: shape (inline — the most-used constraint)

First line is the entry — one sentence stating the event. Hard ceiling:
~10 lines / 150 words total. No headers, no bullet lists, no code blocks,
no restating the diff — the commit already has the mechanics; the entry
carries only what the commit can't (the belief change and the why). Cite
commit hashes. Name experiments and restate verdicts inline. Overflow goes
to a dated note by rule — the entry never grows to fit more. Catch-up
entries get double the budget (~20 lines).

```
# 2026-08-15-1432-switch-to-masked-ncc.md

Switched placement from ECC to masked NCC.

Believed ECC would hold at low overlap (assumption from the April web
search). The masked-ncc experiment showed 2.1px vs 5.8px mean error at
<50% overlap. Lifting the mask-generation approach into the placement
pipeline; ECC path removed. (abc1234)
```

## Landing

A landing is a merge into main, or an explicit decision to abandon a
branch — both run `/lenore-doc-system:land`: final spec sync, closing
journal entry, change folder archived, branch task file disposed with the
user's confirmation on what graduates to `project.md`, desk walked and
cleared, merge as the *last* step. Trigger is plain words ("merge it") —
never a ritual invocation. The pre-push hook gates any `git push` that
updates main/master with structural marker checks — it does not gate a
bare local `git merge` with no push, and it's local config that only
applies once a clone has run `/lenore-doc-system:setup`'s activation
check.

Not a landing: direct-to-main work on Tier 0 (no ceremony), syncing main
into a feature branch, an experiment conclusion on its own, a partial
landing / cherry-pick (journal entry only, branch continues).

## Enforcement

All rule enforcement lives in committed `.githooks/` (`git config
core.hooksPath .githooks`, once per clone): pre-commit rejects modifying
or deleting `docs/journal/`, `docs/notes/` (modify only), and
`experiments/*/runs/*.md`; rejects adding `state.md`/`decisions.md`/
`STATUS.md`/`CHANGELOG.md`/`HANDOFF.md`; rejects non-prose additions under
`docs/`. Pre-push rejects any push to `main` missing landing markers
(leftover `docs/tasks/branch-*.md`, unarchived `openspec/changes/*/`).
`scripts/doc-status.sh` runs at session start on both harnesses and prints
drift — it fixes nothing, it just makes drift visible. No scheduled jobs;
doc maintenance is event-driven only.

## Settled decisions — do not re-litigate

- No `decisions.md`, no ADRs, no entry IDs, no supersession markers.
- No maintained indexes or `_generated/` files — `ls`/`grep`/`browse.py`
  compute everything live.
- No inbox, no librarian subagent — capture is direct, in flow.
- No dedicated docs worktree — unique dated files already kill conflicts.
- No `state.md` — task content → `project.md`; architecture → on-demand
  dated notes; history → backfilled journal.
- No scheduled/cron jobs for doc maintenance.
- No pin-until / frontmatter expiry on desk links — the 14-day mtime check
  covers it.
- No obsolete-markers on notes — deletion, sinking, and "notes aren't
  authority" cover staleness without a status field.
- No monolithic JOURNAL.md/TASKS.md — one file per entry, always.
- No standing ARCHITECTURE.md — demoted to on-demand dated snapshot.

## Reference index

- `references/doc-classes.md` — full per-directory rules (journal, notes,
  reference, tasks, bugs, experiments' three zones, desk incl.
  remove-vs-delete, tmp, scripts, openspec). Read when the trigger table
  above isn't enough detail.
- `references/routing.md` — the question→location table plus when to
  search notes before starting new work.
- `references/rules-tier1.md` / `references/rules-tier0.md` — the exact
  `CLAUDE.md` rules blocks to paste into a repo (install payloads, paste
  verbatim, don't paraphrase).
- `templates/` — working `.githooks/`, `scripts/browse.py`,
  `scripts/doc-status.sh`, `docs/CLAUDE.md`, `.gitignore` snippet.
- `/lenore-doc-system:setup` — propose-then-apply installer, including
  migration of legacy tracking docs.
- `/lenore-doc-system:land` — the landing flow.
- `/lenore-doc-system:desk` — desk review (list, renew-or-drop stale pins,
  suggestions). Interactive only.
- `/lenore-doc-system:doc-cleanup` — hygiene pass over Someday, stale
  branch-task files, and stale bugs; confirmed diffs only. Interactive only.
