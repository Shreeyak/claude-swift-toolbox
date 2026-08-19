# docs/ — formatting details

This file carries formatting details only. Triggers, routing, and the
enforcement model live in the root `CLAUDE.md`; read that first — this file
tells you the exact shape once you already know when to write.

`AGENTS.md` beside this file symlinks to it, so Codex sees the same rules.

## Journal entries (`docs/journal/YYYY-MM-DD-HHMM-topic.md`)

- First line: one sentence stating the event. No heading markup needed —
  the sentence itself is the entry.
- Everything after: optional support, ≤10 lines / 150 words total. No
  headers, no bullet lists, no code blocks. Cite commit hashes in
  parentheses. Name experiments and restate verdicts inline.
- Catch-up entries (summarizing a gap from `git log`) get double the
  budget: ~20 lines.
- Immutable once committed. Fix typos freely before the commit; never
  after.

```
# 2026-08-15-1432-switch-to-masked-ncc.md

Switched placement from ECC to masked NCC.

Believed ECC would hold at low overlap (assumption from the April web
search). The masked-ncc experiment showed 2.1px vs 5.8px mean error at
<50% overlap. Lifting the mask-generation approach into the placement
pipeline; ECC path removed. (abc1234)
```

## Notes (`docs/notes/YYYY-MM-DD-topic.md`)

- Line 1 is always a one-sentence summary — this is what `browse.py`
  displays. For Markdown notes, strip any leading `#` before writing the
  summary as the actual first line of prose.
- HTML notes: an HTML comment at the very top of the file:
  `<!-- one-sentence summary · published: <url-if-published> -->`
- Immutable once committed. Revisiting a topic = a new dated file, not an
  edit to the old one.
- **A note that corrects or supersedes an earlier note names it in its
  body, in plain words** ("revises notes/2026-08-10-x.md"). The old note
  is not edited, gets no marker, and stays unless it's junk
  (human-confirmed delete). This makes succession discoverable in both
  directions with zero infrastructure: newest-first listings and search
  dates surface the newer note, and grepping an old note's filename
  finds its successors. No need to check for supersession on every
  read — notes are never authority, so an old note can't mislead about
  what's true now; check only when about to act on one (the date+class
  rule already says this).
- **Research output** (literature surveys, online research): same dated
  notes, named `YYYY-MM-DD-research-<topic>.md` — the `research-` token is
  the convention that makes `ls docs/notes/ | grep research` and semantic
  search work as "show me our research". The note holds the findings with
  sources cited. What gets *adopted* lands in `docs/playbook.md` or a
  system chapter as one conclusion + a pointer back to the note; claims
  needing empirical validation become experiments.
- **Note bundles** (`docs/notes/YYYY-MM-DD-topic/`): a note may be a
  **directory** only when it will contain members that are NOT prose
  authored by the filing agent — downloaded sources, data files
  (`.csv`/`.json`), figures + their sources, or reports from other
  agents/tools. All-own-prose splits are rejected: one effort, one file.
  Every bundle carries an `index.md` (line 1 = one-sentence summary, then
  what each member is and where it came from — hook-checked). Members may
  be live progress files while the effort runs; **commit the bundle when
  the effort concludes** — committed members are immutable like any note.
  Big/binary evidence (PDFs, >5MB anything) goes to the store, listed in
  `index.md` by store path.
- **Papers and downloaded documents**: never committed. The bytes go to
  `data/library/<topic>/` in the gitignored store; a research note (or a
  bundle's `index.md`) lists each one — title, URL/DOI, one line on why it
  was saved, store path. The note is what search finds; it says where the
  PDF lives.
- **Review output** (subagent/codex/human code reviews): never save the
  raw transcript, and save nothing for findings that were fixed — the
  fix commits are the record. A review earns a note
  (`YYYY-MM-DD-review-<topic>.md`, line 1 = one-sentence verdict) only
  when it holds something that outlives the session: declined findings
  with the reason, or a milestone verdict. Confirmed-but-unfixed bugs go
  to `docs/bugs/` (one file each); design-changing findings go into the
  openspec change/spec, not a note.

## The spine — `system` / `caveats` / `playbook` (living, mutable)

Three question-shaped homes for current truth, beside the specs:

- **`docs/system.md` + `docs/system/`** — *how it works now.* The hub file
  is a one-page map (what this system is + one line per chapter); substance
  lives in chapter files under `docs/system/` (`architecture.md`,
  `data-flow.md`, `state-transitions.md`, `premises.md`, plus earned
  chapters — soft cap ~8, the status line warns). Update a chapter **in
  the same commit that falsifies it**. Figures live beside their chapter,
  with their editable sources (`.d2`/`.excalidraw`/`.mmd`/generator `.py`)
  committed next to the render — a render whose source is lost can't be
  iterated.
- **`docs/system/premises.md`** — ground rules about the product,
  instrument, and operator that every design must satisfy. Numbered
  entries (`**P1 — …**`), each with a provenance pointer (the note or
  experiment that established it) and a consumers hint. Admission test:
  *would this still be true if we rewrote the entire pipeline in another
  language tomorrow?* Yes → premise; no → it's a mechanism, put it in a
  regular chapter. Soft cap ~15 entries. This file is **mandatory
  pre-design reading** — the root `CLAUDE.md` carries the line; cite the
  premise IDs a design rests on or bends.
- **`docs/caveats.md`** — *where it fails now.* One registry of known
  failure modes, limitations, and data hazards. Entries carry **stable
  IDs** (`## C4 — <title>`), sequential, never renumbered or reused. Each
  entry carries a **Validity ladder**, read in order:
  1. `Confirmed:` what is reproducibly observed.
  2. `Mechanism:` the current working explanation (the one to work from).
  3. `Retracted:` earlier readings that were wrong, with the reason.
  The ladder is required — without it, entries quietly assert retracted
  mechanisms. Fix/no-fix stance goes in the entry; an actionable defect
  is a `docs/bugs/` file instead, and graduates to a caveat only if it's
  accepted as a standing limitation.
- **`docs/playbook.md`** — *how we do things.* Procedures, evaluated
  tools (each with a "use when" line + a last-verified date), and adopted
  research conclusions (the conclusion + a pointer to the dated research
  note that established it — never the survey itself).

`caveats.md`/`playbook.md` start as single files; when one outgrows a
file, it becomes a hub + `docs/caveats/`/`docs/playbook/` chapters, same
shape as system. There is no `docs/reference/` — external-tool how-tos
live in the playbook; internal explanations in system chapters.

## Proposals (`docs/proposals/YYYY-MM-DD-topic.md`)

Designed-but-not-committed work: feature designs, parked plans, candidate
directions. **The one revisable dated class** — it's a plan, not a
record. Required front-matter:

```yaml
---
status: proposed | accepted | deferred | superseded | implemented  # hook-checked
created: YYYY-MM-DD
artifact:            # optional — claude.ai artifact URL if one was published
---
```

A proposal and its task pointer are one two-part artifact:
`scripts/lenore-docs.py proposal "Title" <<'EOF' … EOF` creates the file
AND appends `- Proposal: <title> — details: proposals/<file>` to
`docs/tasks/project.md` in the same call. While status is
`proposed`/`deferred` the pointer must exist (the status line flags
orphans); on `accepted` the design becomes an openspec change and the
proposal freezes; on `implemented`/`superseded` the pointer is removed
and the file stays as history. Deferred proposals state their unfreeze
condition in the body.

## Tasks (`docs/tasks/`)

- `branch-<slug>.md`: your session's scratch on this branch, where
  `<slug>` is the branch name with every `/` replaced by `-`. Write
  freely. Other branches' files are read-only context.
- `project.md`: two headings, `## Next` and `## Someday`. Entries: one-line
  title, then ≤5 lines of context. Longer context becomes a dated note the
  line points to by name — `— details: notes/YYYY-MM-DD-topic.md`. Write
  that note at discovery time, while the context is still in-session; the
  pointer can't rot because notes are immutable and never renamed. Details
  never creep into the task file; whoever picks up the task reads the note
  first. Edited only at landings, with the user's confirmation on what
  graduates.
- **Every task entry must be readable by someone with none of your
  session context.** Mid-task shorthand ("re-run the sweep after the
  τ/μ fix") is the classic failure — a week later nobody knows which
  sweep, which fix, or what τ is. Expand: name the files, commits, and
  parameters; state what triggers the task and what done looks like.
  If self-containment takes more than the title + 5 context lines, that
  is the signal for a backing note, not a longer entry.

## Creating entries — `scripts/lenore-docs.py`

Prefer the CLI for creating notes, bugs, journal entries, and tasks — it
generates correct dated filenames, enforces the shape caps with
explanatory errors, and makes task + backing note + pointer a single
atomic operation (a forgotten pointer becomes impossible). Body goes in
via heredoc:

```
uv run scripts/lenore-docs.py note "One-sentence summary" <<'EOF'
Full prose body...
EOF
scripts/lenore-docs.py note "..." --supersedes notes/2026-08-10-x.md <<'EOF' ... EOF
scripts/lenore-docs.py note "..." --research [--bundle]   # research naming; --bundle makes a dated dir + index.md
scripts/lenore-docs.py bug "..." <<'EOF' repro, expected vs actual ... EOF
scripts/lenore-docs.py journal "One-sentence event" [body ≤10 lines/150 words total]
scripts/lenore-docs.py task "Self-contained title" [--someday|--branch] [--note] [context]
scripts/lenore-docs.py proposal "Title" <<'EOF' ... EOF   # dated proposal + task pointer + recall, atomic
scripts/lenore-docs.py experiment "short name"   # dated dir + README + data symlink + store dirs + recall
scripts/lenore-docs.py run <experiment> [slug]   # reserve next run id, mkdir its out/ dir
```

`task --note` files the body as a dated note and appends the
`— details:` pointer to the task line automatically. Plain Write remains
a valid fallback (the hooks still enforce the rules); the CLI is the
convenient path, not a gate.

A commit that touches journal/notes/bugs/tasks files or experiment run
records may be blocked once by an advisory judgment lint (a cheap-model
check of the rules above — self-containedness, real summaries, actionable
bugs, evidence-grade runs, and a new run left contradicting its
experiment's README verdict). Fix what it names rather than bypassing; if
you judge it wrong, re-running the same commit unchanged proceeds.

## Bugs (`docs/bugs/YYYY-MM-DD-topic.md`)

- Line 1: one-line symptom.
- Then ≤5 lines: file/line anchor, repro steps, suspected cause.
- Deleted in the commit that fixes the bug. A journal entry only if the
  bug or its fix was itself notable.

## Experiments (`experiments/YYYY-MM-DD-<name>/`)

One dated dir per experiment: `README.md` (current truth), code at the
root, `notebook/` (the narrative), and a committed symlink
`data -> ../../data/experiments/<same-name>` into the store. Create with
`scripts/lenore-docs.py experiment "<name>"` (makes all of it, including
the store dirs). Picking an experiment back up: read its README, then
`cat notebook/*.md` for the full story.

**README.md** — front matter (machine-scanned one-liners):

```yaml
---
status: exploring | concluded | shelved     # REQUIRED (candidates: exploring | adopted | retired | parked)
question: <one line — what this experiment decides>   # REQUIRED
verdict: <one sentence answer>    # REQUIRED at conclusion (gate-checked)
concluded: YYYY-MM-DD             # REQUIRED at conclusion (gate-checked)
kind: question | candidate-system # optional, default question — see below
success: <one line — what result would settle it>     # optional
uses: [2026-06-01-gpu-pc]         # optional — experiments whose code this reuses
extends: 2026-05-12-plain-ncc     # optional — prior experiment this builds on
artifact: <url>                   # optional — published claude.ai artifact for this experiment
---
```

Headings, fixed order, omitted when empty (never left blank): `Question`
(required — full framing), `Approach`, `Data` (required once data exists —
what `keep/` holds and why, plus the exact `regen/` rebuild command; this
IS the regen manifest), `Findings` (required once runs exist — every
claim cites run ids), `Dead ends & ruled out` (required once anything has
been ruled out — what was tried, set aside, and why; **read before
re-opening any of those threads** — the single cheapest anti-rework
device), `Recommendations`
(conclusion-time), `Caveats`, `Open questions`. Closing line:
`History: notebook/ — catch up with `cat notebook/*.md``. No run-by-run
narrative here — the README is rewritten freely; narrative is notebook/'s
job. Full templates + filled examples: the doc-system skill's
`references/experiment-templates.md`.

Concluding is atomic: the commit that flips `status` must carry a real
`verdict:`, the `concluded:` date, and a new journal entry — the
pre-commit hook rejects the flip without all three. When later runs
contradict the standing verdict, update the README in the same commit as
the entry; the commit lint flags a contradicting entry that leaves the
README untouched, and the status line counts experiments with ≥2 entries
newer than their README's last commit (`unreflected-runs`).

## Candidate systems (`kind: candidate-system`)

An exploratory **alternative architecture** — a whole candidate pipeline
or subsystem, not a question-shaped experiment — still lives under
`experiments/` (quarantine for free: its docs can't be mistaken for
current truth, the isolation hook keeps production from importing it, the
promotion path already exists). Mark it `kind: candidate-system` in the
README front-matter. That buys three exemptions and imposes three
requirements:

- *Exempt from*: the dated dir name, the `notebook/runNNN` structure, and
  the store trio — a candidate has code, design docs, and a `results/`,
  not numbered runs.
- *Requires*: (1) a **document map** section in the README — one line per
  file in the dir saying what it is; (2) a **`Dead ends & ruled out`**
  register ("read this before re-opening any of those threads");
  (3) a **verdict on conclusion** — `status: adopted` (its architecture
  docs are copied into `docs/system/` chapters + a `PROMOTIONS.md` line),
  `retired` (one line in the playbook's retired registry naming the git
  tag that preserves it), or `parked` (README status flip only, with the
  unpark condition stated).

Its own core docs (architecture, data flow) live **inside its dir** as
ordinary files while it's a candidate — never in `docs/system/`, or the
spine acquires a second, competing "how it works now."

## Experiment figures (`experiments/<name>/figures/`)

Reviewed deliverable images — annotated overlays, comparison grids,
anything the human actually looked at or an artifact embeds — are
committed under the experiment's `figures/`, size-capped (5MB/file,
hook-enforced). Raw outputs still never leave the store; `figures/` holds
only what was curated for human eyes. Name figures after their run when
they belong to one (`run003-overlay.png`).

## Notebook entries (`experiments/<name>/notebook/runNNN[-slug].md`)

One immutable entry per run; entries sort by name so `cat notebook/*.md`
is the journal in order. Run ids: zero-padded global per-experiment
counter, no dates; next id = max(NNN across `notebook/` and the store's
`out/`) + 1. **Reserve the id first**: `mkdir
experiments/<name>/data/out/runNNN-slug/` (the store path
`data/experiments/<name>/out/…` via the committed symlink) before the run
writes anything (atomic across worktrees;
`scripts/lenore-docs.py run <experiment> [slug]` does it and prints the
paths). Shape:

```markdown
# run002-tau-sweep — 2026-08-20
<one-sentence outcome summary — what this run established>

command: <exact invocation>
commit:  <hash, or "uncommitted — see date">
inputs:  <dataset / keep / regen identity, precise enough to re-run>
outputs: data/out/run002-tau-sweep/   (anchors are experiment-relative, via the data symlink)

## What happened
<prose — what was done and observed, surprises included; for a sweep,
the shape of the result across points>

## Interpretation
<prose — what it means for the question, confidence, what's next>
```

Both prose sections required; 2–3 sentences each is legitimate. A sweep
is ONE run (points as subdirs of its out/ dir); a code-free analysis
entry uses the same shape. Never edited or deleted after commit — a
wrong entry is corrected by a later entry; dead ends stay on record.

Non-`.md` files in `notebook/` are **promoted artifacts** — small result
CSVs and hand-picked figures, named after their run
(`run002-tau-sweep-grid.csv`), committed beside the entry. Raw outputs
never go here (they live in the store); artifacts arrive only by
deliberate promotion and may be replaced/deleted at later cleanups.

## Experiment data — the store (`/data/`, gitignored)

All bytes live under `/data/`: `datasets/` (shared inputs) and per
experiment `regen/` (regenerable — delete freely, README records the
rebuild), `keep/` (custom non-regenerable — deletion only suggested), and
`out/<runid>/` (ALL raw run outputs, heavy and small together, never
split by size). Worktrees carry one symlink to the main checkout's
`data/` — bytes exist once; deleting a worktree loses nothing. Triage
happens at `/doc-cleanup` rounds (delete / keep / promote per run dir),
never automatically. A `data/experiments/<name>` with no matching
`experiments/<name>` in git is an orphan — usually a rename that forgot
`mv data/experiments/<old> data/experiments/<new>` (the pre-commit hook
warns at rename time).

## Experiment isolation and reuse

Production code never imports from `experiments/` and never symlinks into
it (pre-commit enforces both). Promotion is by copy into the production
tree + one line in `experiments/PROMOTIONS.md` (append-only: date,
source, destination). Experiment-to-experiment reuse is fine and
first-class: relative-path imports plus a `uses: [<exp>]` line in the
consumer's README front matter. Concluded ≠ deleted — `uses:` keeps
working; promotion is due when a third consumer appears or the code
starts being edited for its consumers.

## Merged twins (same-named notes from parallel sessions)

If a merge conflicts on a same-named dated note or bug filed by two
sessions, default to keeping both: one under the original name, the other
refiled under a new dated name — the pre-commit hook blocks a silent drop
and prints the exact command. If you have read the dropped version and
judge it junk, dropping it is a valid resolution: re-run the same commit
unchanged and it proceeds.

## Experiment data

Never committed — `data/`, `experiments/*/data/`, `experiments/*/out/`
are gitignored. Data lives in the MAIN checkout; worktrees symlink to it
instead of copying. Record every dataset's regeneration command (or
source + hash) in the experiment README; regenerable data of concluded
experiments gets cleaned up by /doc-cleanup.

## Desk (`docs/desk/`)

Managed via plain words, not commands. Symlink name is a short descriptive
label picked by the agent on creation; the human may rename it freely
afterward — renaming the symlink never touches the target.

## Semantic index (`.docs-embeddings/`, optional)

If present, this whole tree (docs/**/*.md, docs/**/*.html,
experiments/*/README.md, experiments/*/notebook/*.md, and openspec/**/*.md
except tasks.md) is semantically indexed for
`scripts/docs-search.py`. The index is gitignored and content-hash keyed
per chunk, so new or changed docs are picked up automatically by the next
`docs-search.py` run — no separate reindex step required for routine
edits. See `references/semantic-search-setup.md` in the doc-system skill
if it's missing and you want to set it up.

## Semantic search while coding — the rules

- **Search before designing, not before typing.** Run
  `uv run scripts/docs-search.py "query"` when about to propose a design,
  write an openspec change, or start an experiment — the question is "has
  this repo already explored this?" Trivial edits, mechanical refactors,
  and bug fixes with a known cause need no search.
- **Search on unfamiliar vocabulary.** When a comment, spec, or the user
  uses a project term you can't ground in code, search the term before
  guessing — concepts and vocabulary are what embeddings are for.
- **Before re-running or proposing an experiment, search for its
  verdict.** A concluded experiment's README outranks your intuition.
- **Exact values go to grep, never here.** Numbers, thresholds, flags,
  config keys, error strings, file names, "list every place that…" —
  embeddings retrieve the topic, not the value, and will happily surface
  an adjacent table's figure.
- **Results are pointers, not answers.** Open the top 1-3 files and read
  them; never quote a fact from the result row's summary line alone.
- **Check the date and class before trusting.** Dated files (journal,
  notes, runs, archived changes) are snapshots of what was believed then;
  `openspec/specs/` and `CLAUDE.md` are what's true now. A dated hit that
  contradicts a spec loses.
- **Never cite a figure you found semantically without re-finding it
  exactly** — confirm any number or identifier with grep or by reading it
  at its own line in the opened file. This is the single most common
  failure mode.
- **Low scores mean stop.** If nothing scores well (the tool warns below
  ~0.35), the answer likely isn't in the docs — say so or grep; don't
  stretch a weak hit into support for your design.
- **Phrase queries as concepts, not keyword lists.** A short natural
  sentence naming the idea ("why was GPU-side sorting rejected", "seam
  visibility from feathered blending") retrieves better than bare
  keywords, and one concept per query beats several ORed together. If
  the first phrasing scores weak, rephrase once with different
  vocabulary before falling back to grep.
- **Write for retrieval.** Any doc long enough to split into chunks
  (~1500+ tokens) needs real, descriptive headings — a buried fact is
  found through its section's heading and text. When sibling sections
  hold near-identical content (per-scenario tables, per-arm configs),
  the headings must name what differs.
