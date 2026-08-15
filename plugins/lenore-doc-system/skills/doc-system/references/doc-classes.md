# Doc classes — full per-directory rules

Read when you need the complete rule for a specific directory, not just the
trigger table in SKILL.md. Journal entry shape (line-1 rule, ≤10 lines/150
words, overflow-to-note) lives in SKILL.md §3, not here — nothing else in
this file repeats it.

## `CLAUDE.md` — the hub

Short: tier declaration, conventions, hard invariants, build commands, the
rules block (from `rules-tier1.md` / `rules-tier0.md`). One of the three
homes of current truth. `AGENTS.md` symlinks to it so Codex reads the same
file. Written when a convention proves durable — the same correction made
twice graduates here.

## `docs/journal/` — the story

One immutable file per entry, `YYYY-MM-DD-HHMM-topic.md`. Non-authoritative
history: what happened; on direction change, what was believed / learned /
done differently now. Names experiments and restates their verdicts inline
— a journal scan alone tells what was done. Cites commit hashes. Never
edited, no IDs, no statuses. Triggers and shape: SKILL.md §3.

## `docs/tasks/` — working memory

- `branch-<name>.md`: disposable single-owner scratch for that branch's
  session. Write freely. Other sessions read it (via sibling worktrees or
  `git show`), never write it. Deleted at landing after the owner confirms
  what graduates.
- `project.md`: two sections. *Next* (decided, not now) and *Someday* (kept
  small — a real backlog is the signal to move to an issue tracker).
  Entries: one-line title + ≤5 lines context; longer context becomes a
  dated note the line points to. Edited only at landings, with the user's
  confirmation on what graduates.

## `docs/bugs/` — the live bug list

One disposable file per bug, `YYYY-MM-DD-topic.md`: one-line symptom, then
≤5 lines — file/line anchor, repro, suspected cause. Created by *any*
session the moment a bug is noticed: an agent spotting one mid-task files
it without derailing the current task; a plain "file a bug: X" works
anytime. Unique filenames mean parallel sessions never conflict.

`ls docs/bugs/` is always the live list. The fixing session deletes the
file *in the fix commit* — the commit is the record; write a journal entry
only if the bug itself was notable. Disposable like task files, not
history like the journal.

## `docs/notes/` — dated snapshots

Every ad-hoc artifact — explorations, comparisons, explainers, flow
diagrams, long task context, architecture snapshots — as
`YYYY-MM-DD-topic.md`. The date marks it as thinking-on-that-day: it can't
drift, only age. Immutable once committed; revisiting a topic means a new
note, not an edit. Line 1 is always a one-sentence summary — that's what
`browse.py` shows.

## `docs/reference/` — living how-tos

For things *outside* the repo that must stay current: CLI-tool
integrations, workflow setups, external API quirks, research summaries
consulted repeatedly. Named (`ferry-cli-integration.md`), not dated, and
**editable** — exempt from the immutability hook, updated in place when the
external thing changes.

Routing: thinking about *this project* on a given day → `notes/` (dated,
immutable). How to use *something external* → `reference/` (named,
living). A stale reference doc fails loudly the moment it's followed, so
its drift risk is low-damage.

## `experiments/` — trials (repo root, not under `docs/`)

`README.md` per experiment: front-matter (`status`, `verdict`, `concluded`)
+ four sections — Question / What worked / What didn't / Lifted into
production / Not pursued. `runs/`: one immutable file per run — exact
command, config, dataset identity, code commit, metrics, one-paragraph
interpretation. Dead ends included, never cleaned up.

### The three zones of an experiment folder

An experiment mixes three disciplines; keeping them straight is what the
hooks encode:

- **`src/`, `out/`, `data/` — freely mutable, always.** Experiments
  iterate; this is just code. Heavy artifacts gitignored.
- **`README.md` — mutable, deliberately.** The *current* scannable face:
  status front-matter flips, the What worked / Lifted sections get
  rewritten as understanding sharpens. One of the homes of current truth,
  and current truth must be editable.
- **`runs/*.md` — immutable once committed.** Each run's record is
  *evidence*, not description: "at commit `abc1234`, with these
  parameters, we measured 5.8px." Nobody can quietly revise it later —
  immutability makes tidying (deleting "unimportant" runs, summarizing ten
  into one) impossible at the layer where it would destroy information.
  The tidy summary is the README's job, layered on top.

In practice: run 14 lands as `runs/2026-08-15-1102.md` and never changes;
the README's verdict line is rewritten to reflect it; if it changed
project direction, a journal entry restates it. Raw evidence (frozen),
current summary (living), narrative (frozen) — same invariant as the
journal, no special case to remember.

## `openspec/` — plans and feature truth

The OpenSpec workflow, used as-is. Specs are as-built truth, updated in the
same commit as the code they describe. Every feature/implementation plan
becomes a `changes/<name>/` folder (even unstarted — that's the parking
spot); dropped plans move to archive with one line saying why. Never loose
`PLAN-*.md` files.

## The desk (`docs/desk/`)

A literal directory of symlinks, gitignored and per-worktree, managed by
agents for the human's 3–8 currently-important docs. Not the same as
`docs/tasks/` (agent-facing working memory) — the desk is human-facing
reading set; the only coupling is both get walked at landing.

- **Auto-pin.** Anything produced *for* the human (a diagram, a comparison,
  requested research) is symlinked onto the desk in the same message it's
  created, under a descriptive name the agent picks. The original always
  lives in its normal home (usually `docs/notes/`) — the desk holds only
  links, so clearing it never loses a document. Rename the symlink freely
  afterward; the name is the human's, the target doesn't care.
- **Plain words only.** "Put on / take off my desk" does what it says, any
  time. No CLI tool is required — `ln -s` is all an agent needs.
- **Two expiry paths, so it can't accumulate by inertia.** Links older than
  14 days are flagged stale by `browse.py` and counted in the status line —
  when a session sees the flag, it asks the user renew-or-drop. The landing flow walks the desk before clearing it —
  each pin either disappears (default) or, if the user says keep,
  graduates to one pointer line in `project.md`.
- **Remove vs delete — the deletion policy in one line.** "Take it off my
  desk" (or deleting the symlink directly) removes only the tracking; the
  original stays wherever it lives. "Delete it" removes the symlink *and*
  `git rm`'s the original — **allowed for notes, reference docs, bugs, and
  tmp files** (a `git rm`'d file is one command away in git history, so
  immutability — meaning no silent revision — is preserved while junk
  leaves the listings); **never for journal entries or run records** (the
  pre-commit hook rejects it — they are history and evidence, and this is
  exactly the rule that stops "tidying" of failed runs). An unwanted
  journal or run link just gets removed from the desk and ignored.
  Deletion is human-initiated only — agents never delete unprompted, and
  every deletion shows as a diff before it happens.
- **Autonomous mode.** When the human is not present to make destructive or
  pruning calls (a standing "act autonomously" instruction is in effect),
  the landing flow skips the desk walk entirely, leaves every pin in
  place, and records "desk not reviewed" in the closing journal entry —
  the next interactive session or the status-line nudge picks up the walk.
  The rule for which mode applies is explicit, not inferred: only ask when
  the human is in the conversation; a standing autonomy instruction means
  *defer* judgment calls, never make them silently.
- **No git surface, no rot.** Untracked symlinks have no content to go
  stale and no git presence to conflict. A dangling link (its target
  deleted, e.g. a bug file removed in a fix commit) is auto-filtered and
  reported by `browse.py`, not silently left dangling.

## `tmp/` — throwaway

Scratch scripts, hack-plans, one-off outputs. Gitignored wholesale —
nothing in it can become history or be mistaken for a real doc, no hook
needed. Ephemerality enforced by construction; keeping something means
moving it out of `tmp/` into its real home.

## `scripts/`

Every script opens with two comment lines: `# usage:` and
`# what it does:`. No `scripts/README.md` — `browse.py` reads these header
lines directly, so there is nothing else to maintain.
