# Doc guidance — the full rules and recommendations, per directory

The single home for guidance and recommendations on writing and managing
docs: read when you need the complete rule for a specific directory, not
just the trigger table in SKILL.md. Journal entry shape (line-1 rule, ≤10
lines/150 words, overflow-to-note) lives in SKILL.md §3, not here — nothing
else in this file repeats it. Adjacent references stay specialized:
`routing.md` (where things go / where to look), `semantic-search-setup.md`
(search + chunking guidance), `rules-tier1.md`/`rules-tier0.md` (verbatim
CLAUDE.md paste payloads).

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
  dated note the line points to — `— details: notes/YYYY-MM-DD-topic.md`,
  written at discovery time while the context is in-session
  (`lenore-docs task --note` creates note + pointer atomically). The
  pointer can't rot: notes are immutable and never renamed. Every entry
  must pass the stranger test — a competent developer with none of the
  writing session's context can act on it because every referent (file,
  commit, dataset, parameter) is locatable from the repo. Edited only at
  landings, with the user's confirmation on what graduates.

### Same-named notes from parallel sessions

Two worktrees or branches can file the same `YYYY-MM-DD-topic.md` name
independently; the merge then hits an add/add conflict between two
immutable files. Doctrine: **both versions survive.** Keep one under the
original name, refile the other's exact content under a new dated name
(`git show MERGE_HEAD:docs/notes/<f>.md > docs/notes/YYYY-MM-DD-<new-slug>.md`),
then complete the merge — the pre-commit hook blocks a merge that silently
drops either version and prints this recovery. Dropping one twin IS a valid
resolution when you have read it and judge it junk or duplicate: re-run the
same merge commit unchanged and it proceeds (warn-once — only a SILENT drop
is blocked, and a deliberate one costs one retry).

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

A note that corrects or supersedes an earlier note names it in its body
in plain words ("Revises notes/2026-08-10-x.md"). The old note gets no
marker and is never edited; it stays unless it's junk (human-confirmed
delete). Succession is discoverable both ways with zero infrastructure:
date-sorted views surface the newer note above the older, and grepping an
old note's filename finds its successors.

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

One experiment = one dated dir `experiments/YYYY-MM-DD-kebab-name/`
holding exactly four committed things plus one symlink:

```
experiments/2026-08-18-masked-ncc/
├── README.md          current truth: question, status, verdict, findings
├── match.py  run.sh   the experiment's code, root-flat (subdirs when earned)
├── notebook/          the narrative: one immutable entry per run + promoted
│   ├── run001-baseline.md            artifacts named after their run
│   ├── run002-tau-sweep.md
│   └── run002-tau-sweep-grid.csv
├── data -> ../../data/experiments/2026-08-18-masked-ncc
└── .venv/  vendor/    tool state — gitignored in place, never in the store
```

All bytes live in the store, one gitignored root `/data/`:

```
data/
├── datasets/                          shared cross-experiment source data
└── experiments/2026-08-18-masked-ncc/
    ├── regen/    regenerable inputs — delete freely; README records the rebuild command
    ├── keep/     custom non-regenerable inputs — deletion only ever suggested
    └── out/      ALL raw run outputs, heavy+small together, one dir per run
        └── run002-tau-sweep/          a sweep is ONE run; points are subdirs
```

There is no fifth place anything can live. Dates go on experiment dirs
(lineages need at-a-glance chronology), never on run names.

### README.md — current truth, zero narrative

Front-matter one-liners are the envelope machines scan: `status:`
(exploring | concluded | shelved), `question:`, `verdict:` + `concluded:`
(gate-checked at conclusion), optional `success:` (what result would
settle it), `uses:` (experiments whose code this reuses), `extends:`.
Headings are the letter, in fixed order — Question (required: the full
framing), Approach (how to operate the experiment cold), Data (required
once data exists — what `keep/` holds and why it's irreplaceable, plus
the exact `regen/` rebuild command; this section IS the regen manifest),
Findings (required once runs exist — current understanding, every claim
citing run ids), What didn't work (dead ends with the run that killed
each), Recommendations (conclusion-time: what production should adopt),
Caveats, Open questions. Omitted sections are omitted, never left as
empty headings. Closing line, fixed: `History: notebook/ — catch up with
`cat notebook/*.md``. Rewritten freely as understanding changes — no
run-by-run story here, ever. Full template with rationale + a filled
example: this skill's `references/experiment-templates.md`.

### notebook/ — the narrative, one entry per run

The notebook is a directory, not a file: run entries sort by name, so
`cat notebook/*.md` is the journal in chronological order — that command
is the standing catch-up move when picking an experiment back up. Naming:
`runNNN[-slug].md`, zero-padded global per-experiment counter, no dates
(the entry's own date line and git answer "when"). Next id =
max(NNN across `notebook/` and the store's `out/`) + 1, so an uncommitted
run still claims its number; **`mkdir experiments/<name>/data/out/runNNN-slug/`
before anything else** — creating the out dir first reserves the id atomically
across concurrent worktrees.

When is an entry required? Every completed run whose outputs you actually
looked at gets one — failures included (a refuted hypothesis is evidence).
A reservation abandoned before producing anything interpretable (crashed
setup, wrong command) needs no entry; its out dir is deleted at triage.
An out dir with no entry is therefore a triage flag, not proof of noise.

Entry shape: `# runNNN[-slug] — YYYY-MM-DD` header; line 1 below it is a
one-sentence outcome summary (same envelope rule as notes); then the
anchor lines `command:` / `commit:` / `inputs:` / `outputs:`; then two
required prose sections — `## What happened` (the narrative, surprises
included; for a sweep, the shape of the result, not just the best point)
and `## Interpretation` (what it means for the question, what the next
run should be). Short is fine; absence is not. A code-free analysis entry
uses the same shape. Entries are immutable on commit — a wrong entry is
corrected by a later entry, never edited; dead ends stay on record.

Vault rules, two clauses: every `.md` in `notebook/` is an immutable run
entry; anything else is a **promoted artifact** named after its run
(`run002-tau-sweep-grid.csv`) — small result CSVs and hand-picked
figures, committed beside the entry they support. Artifacts are
replaceable/deletable at cleanups (deletes are legal, rewrites of entries
aren't). Raw outputs never land here — they go to the store; git-worthy
keepers arrive only by deliberate promotion (at write time when you
already know, at the cleanup round as the backstop).

### The store, worktrees, and cleanup

The run id joins the two roots by name: `notebook/run002-tau-sweep.md` ↔
`data/.../out/run002-tau-sweep/`. Worktrees (`.claude/worktrees/`,
`.worktrees/` — both gitignored) get ONE relative symlink at worktree
root, `data -> <main repo>/data`, so bytes only ever live in the main
repo's store: deleting a worktree loses nothing, and entries/artifacts
merge as ordinary committed files.

Curation is retrospective and batched — at write time nobody reliably
knows which outputs will matter, so the system never asks. Everything
lands in `out/<runid>/` unsorted; the `/doc-cleanup` triage pass (run it
when the status line's untriaged-runs counter says so — it is interactive,
never scheduled)
walks untriaged run dirs and decides per run: **delete** (question
answered, bytes worthless), **keep** (still comparing against it), or
**promote** (copy the few files that matter into `notebook/`). It also
deletes `regen/` and `.venv`/`vendor` of concluded experiments, suggests
stale `keep/` deletions, and flags orphans — a `data/experiments/<name>`
with no matching `experiments/<name>` in git (the one orphan definition;
often a rename that forgot to `mv` the store dir — the pre-commit hook
warns at rename time). Forgetting to curate costs disk, never data.

### Lifecycle and enforcement

Start: `scripts/lenore-docs.py experiment <name>` creates dir + README +
symlink + store trio (by hand also fine — the shape is checkable, the
tool is a convenience). Conclude: flip `status:` — the pre-commit hook
requires a real `verdict:`, a `concluded:` date, and a same-commit
journal entry. Concluded ≠ deleted: the dir, notebook, and artifacts stay
in git forever. Code graduating to production is promoted **by copy**,
recorded as one line in `experiments/PROMOTIONS.md` (append-only ledger:
date, source, destination, copied vs cited).

Cross-experiment reuse is first-class: experiment B may use A's code by
relative path (`-I ../<exp-A>`, path imports) — the entire dependency
system is one README front-matter line, `uses: [<exp-A>]`. Cleanup greps
`uses:` and `../<name>` before suggesting any experiment dir's deletion.
Reuse converts to promotion when a third consumer appears or A's code
starts being edited to serve its consumers. No `experiments/_shared/` —
a shared dir inside experiments/ is a library with no owner.

Isolation stays one-way: production never imports from or symlinks into
`experiments/` (pre-commit rejects both; intra-experiments references are
exempt). If a dir in `experiments/` has no question, it is not an
experiment and gets flagged for relocation — integration workspaces and
demo apps live in the normal repo structure.

The judgment lint checks new notebook entries for evidence anchors and
flags an entry contradicting the README's `verdict:`/Findings while the
README goes untouched; the status line counts experiments with ≥2 entries
newer than their README's last commit (`unreflected-runs`), plus
untriaged out/ dirs and orphaned store dirs.

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
  every deletion shows as a diff before it happens. Before deleting a
  note, grep `docs/` for its filename — a hit in a task file means a
  task still depends on it: drop the pointer too or reconsider the
  deletion.
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
