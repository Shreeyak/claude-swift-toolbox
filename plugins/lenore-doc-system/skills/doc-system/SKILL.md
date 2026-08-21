---
name: doc-system
description: Rules for writing, filing, and finding documentation in a repo using the Lenore doc system — the system/caveats/playbook spine, proposals, journal, notes, tasks, bugs, experiments, desk, landing. Invoke before creating or moving any doc file, before landing a branch, or when adopting the system in a new repo.
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
CLAUDE.md                    hub: tier, conventions, invariants, doc rules,
                             the premises pre-design read line
openspec/
  specs/                     as-built feature truth — committed atomically with code
  changes/                   in-flight work; archived on landing
docs/
  CLAUDE.md                  formatting details only (entry shapes, front-matter)
  system.md                  SPINE: how it works now — one-page hub, chapters below
  system/                    architecture.md · data-flow.md · state-transitions.md ·
                             premises.md (named ground rules — mandatory pre-design
                             read) · earned chapters · figures + their sources
  caveats.md                 SPINE: where it fails now — named entries (never
                             numbered), each with a Validity ladder
                             (Confirmed/Mechanism/Retracted)
  playbook.md                SPINE: procedures · evaluated tools (use-when +
                             last-verified) · adopted research conclusions
  proposals/2026-08-20-topic.md   designed-not-committed; the ONE revisable dated
                             class; status: front-matter + mandatory task pointer
  journal/2026-08-15-1432-topic.md    one immutable file per entry
  notes/2026-08-02-topic.md           dated, immutable; line 1 = summary;
                             research- prefix for research output; dated bundle
                             DIRS (index.md + non-own-prose members) allowed
  desk/                      gitignored, per-worktree symlinks (see doc-guidance.md)
  tasks/project.md · branch-<name>.md
  bugs/2026-08-15-topic.md
experiments/                 repo ROOT, not docs/ — one dated dir per experiment
  PROMOTIONS.md              append-only ledger of code promoted to production
  YYYY-MM-DD-<name>/         README.md (current truth) · code at root ·
                             notebook/runNNN[-slug].md entries + promoted
                             artifacts · figures/ (curated human-reviewed images) ·
                             data -> ../../data/experiments/<same>
  <candidate>/               kind: candidate-system README — alternative
                             architectures; own docs INSIDE; adopted/retired/parked
data/                        THE STORE, gitignored: datasets/ + library/<topic>/
                             (papers, PDFs) + per-experiment regen/ · keep/ ·
                             out/<runid>/ (all raw run bytes)
.githooks/                   pre-commit · commit-msg · pre-merge-commit · pre-push — all rule enforcement
scripts/browse.py · doc-status.sh · lenore-docs.py · docs-search.py
tmp/                         gitignored wholesale
```

`docs/` is a **closed layout** — the pre-commit hook rejects any
top-level child outside the set above, plus per-area extension rules
(prose everywhere; figures and their editable sources beside spine
chapters and inside note bundles; `.csv`/`.json` only inside bundles;
5MB/file cap). There is no `docs/reference/` — tools/procedures live in
the playbook, internal explanations in system chapters. Full
per-directory rules: `references/doc-guidance.md` (read when you need
the complete rule for the spine / proposals / journal / notes incl.
bundles / tasks / bugs / experiments' three zones / candidate systems /
desk semantics incl. remove-vs-delete / tmp / scripts / openspec).

**Routing in ten seconds** — how it works now → `system` chapter (same
commit that falsifies it); ground rule about product/instrument/operator
→ `premises.md`; where it fails / hazard → `caveats.md`; procedure /
evaluated tool / adopted research conclusion → `playbook.md`; adopted
feature contract → openspec; designed-but-not-committed → `proposals/` +
task pointer; repair → `bugs/`; later → `tasks/`; dated evidence,
research, or thinking → `notes/`; empirical question or candidate
architecture → `experiments/`. **Unsure → dated note** — the escape
hatch is always correct.

## When X happens, do Y

| Trigger | Action |
|---|---|
| Creating any journal entry, note, bug, task, or proposal | Prefer `scripts/lenore-docs.py note\|bug\|journal\|task\|proposal "summary"` with the body as a heredoc — correct dated filename, shape caps with explanatory errors, atomic task+note+pointer (`task --note`) and proposal+pointer, `--supersedes` for corrections. Plain Write stays valid; hooks backstop. |
| Something belongs in current truth | Route by question: how it works now → `docs/system/` chapter (updated in the same commit that falsifies it); hazard/limitation → `docs/caveats.md` entry (named slug heading + Validity ladder — never an ID); procedure, evaluated tool, or adopted research conclusion → `docs/playbook.md`. |
| About to design, propose, or start an experiment | Read `docs/system/premises.md` first; name the premises the design rests on or bends, in plain words. The CLI's recall step also surfaces related prior notes/proposals/experiments. |
| A designed plan isn't being built now | `scripts/lenore-docs.py proposal "Title"` — dated file (status: proposed) + task pointer, one call. Flip status as it moves: accepted → openspec change; deferred (state the unfreeze condition); implemented/superseded → remove the pointer, file stays. |
| Research task (literature/online survey) | Findings → `docs/notes/YYYY-MM-DD-research-<topic>.md` (`note --research`); multi-file output (downloaded sources, other agents' reports, data) → a dated bundle (`note --research --bundle`), members listed in its index.md. PDFs/papers → `data/library/<topic>/`, listed in the note. Adopted conclusions graduate to playbook/system with a pointer back. |
| Exploring a whole alternative architecture | An experiment with `kind: candidate-system` — own docs inside its dir, document-map README section, Dead ends & ruled out register; concludes as adopted (docs → `docs/system/` + PROMOTIONS line) / retired (playbook registry line + git tag) / parked (unpark condition stated). |
| Publishing a claude.ai artifact from repo content | Record the URL where the file lives: `artifact:` front-matter (proposal/experiment README) or `published: <url>` in the HTML's top comment — the status line flags committed HTML with no URL. |
| Bug noticed (by anyone, any time) | File `docs/bugs/YYYY-MM-DD-topic.md` now — one-line symptom + ≤5 lines with a repro. Don't derail current work. Delete it in the fix commit (the commit-msg hook rejects a fix claim that doesn't). |
| Openspec phase / task-group completed | Write a journal entry (shape below). |
| A committed note turns out wrong or superseded | New dated note whose body says "Revises notes/YYYY-MM-DD-x.md" — never edit or mark the old one; grep the old filename to find successors. |
| Filing a future task | Entry must pass the stranger test — every referent (file, commit, dataset, parameter) locatable from the repo alone; >5 lines of context → backing note + `— details: notes/...` pointer (`lenore-docs task --note` does both atomically). |
| Starting an experiment | `scripts/lenore-docs.py experiment "<name>"` — dated dir + README skeleton + notebook/ + data symlink + store trio. Templates: `references/experiment-templates.md`. |
| Launching an experiment run | `scripts/lenore-docs.py run <exp> [slug]` (or `mkdir experiments/<exp>/data/out/runNNN-slug/` by hand) FIRST — reserves the id; all outputs go there. When the run means something, write `notebook/runNNN[-slug].md` (outcome sentence, command/commit/inputs/outputs, What happened + Interpretation). |
| Picking an experiment back up | Read its README, then `cat notebook/*.md` — the entries sort chronologically; that IS the journal. |
| Experiment concluded | Flip the README's `status`/`verdict` front-matter, then a journal entry restating the verdict — same session. Concluded ≠ deleted; code promoted to production goes by copy + a `PROMOTIONS.md` line. |
| Reusing another experiment's code | Relative-path import + `uses: [<exp>]` in your README front-matter. One line, that's the whole dependency system. |
| Direction changed | Journal entry: what we believed / learned / do now. |
| Milestone hit, no change folder (exploratory branch) | One journal entry per concluded work-topic. |
| Status line shows a large gap | One catch-up journal entry (~20 lines) summarizing the arc from `git log` — don't back-fill many. |
| You produce a doc FOR the user | Save it in its normal home (usually `docs/notes/`), symlink it into `docs/desk/` in the same message. |
| User states business context, or an outcome a non-technical stakeholder would care about | Append ONE line to `## Stakeholder notes` in the branch task file. Sparse — most milestones get no line. |
| User wants a report for non-technical stakeholders | Run `/lenore-doc-system:brief` — compiles journal span + stakeholder notes + verdicts + figures into a self-contained HTML note (`docs/notes/YYYY-MM-DD-brief-<slug>.html`); user reviews before commit. |
| User says "put/take X on/off my desk" or "delete X" | Do it in plain words — see `references/doc-guidance.md` desk section for remove-vs-delete semantics. |
| Branch is landing or being abandoned | Run `/lenore-doc-system:land`. Never a bare `git merge` — into main OR any other branch; a branch whose task file is still open must be closed out before its work is integrated anywhere. |
| Repo has no doc system yet, or needs upgrading | Run `/lenore-doc-system:setup`. |
| Before a proposal/design, or "did we try this before?" | Search `docs/notes/` + experiment READMEs (`scripts/browse.py --plain` or grep) — see `references/routing.md`. |
| Any "where do I find X" question | `references/routing.md` — the question→location table. |
| Concept/vocabulary question over past docs ("did we explore X?") | `scripts/docs-search.py "query"` if `.lenore/embeddings/` exists (local jina-v5 embeddings on MLX); else grep + `browse.py --plain` — not set up yet → `references/semantic-search-setup.md`. |

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
branch — both run `/lenore-doc-system:land`: final spec sync (approved
deltas only — built-vs-planned divergence is raised to the user, never
papered over by editing specs), closing journal entry, change folder
archived (fully-checked tasks auto-archive; a few pending tasks need
the user's defer-or-stay decision), branch task file disposed with the
user's confirmation on what graduates to `project.md`, desk walked and
cleared, the reverse-drift sync review (step 4b: `truth-candidates.sh`
manifest → `code-doc-sync-reviewer` agent → report saved to
`docs/notes/` — an evidence-backed finding gates warn-once; see
`references/reverse-drift-check.md`), merge as the *last* step. Trigger is plain words ("merge it") —
never a ritual invocation. This applies to merges into ANY branch, not
just main — merging feature X into feature Y while X's branch task file
is still open is the same skipped close-out. Manual merges are checked
the same way: a landing guard fires at both layers (an agent-harness
PreToolUse hook on `git merge` commands, and the `pre-merge-commit` git
hook for user-typed merges) whenever the merged branch's
`docs/tasks/branch-<slug>.md` still exists — the land flow deletes that
file before merging, so its presence means the flow has not run. The
guard warns once and blocks; re-running the identical merge proceeds
(`LENORE_NO_MERGE_GUARD=1` skips). Setup also sets `git config merge.ff
false` (with `pull.ff true`): no git hook fires on a pure fast-forward,
so forcing merge commits is what makes the git-layer guard cover every
merge. The pre-push hook additionally gates any `git push` that updates
main/master with structural marker checks; all of this is local config
that only applies once a clone has run `/lenore-doc-system:setup`'s
activation check.

Not a landing: direct-to-main work on Tier 0 (no ceremony), syncing main
into a feature branch, an experiment conclusion on its own, a partial
landing / cherry-pick (journal entry only, branch continues).

## Enforcement

All rule enforcement lives in committed `.githooks/` (`git config
core.hooksPath .githooks`, once per clone): pre-commit rejects modifying
or deleting `docs/journal/`, `docs/notes/` (modify only), and
`experiments/*/notebook/*.md`; rejects adding `state.md`/`decisions.md`/
`STATUS.md`/`CHANGELOG.md`/`HANDOFF.md`/`PLAN-*.md`/`REVIEW-*.md`;
rejects non-prose additions under `docs/`; and shape-checks new
journal/notes/bugs files (prose line-1 summary; journal ≤10 lines /
150 words, no headers or bullets). It also enforces the closed docs/
layout (fixed top-level set; per-area extensions — figure sources beside
spine chapters and in bundles, `.csv`/`.json` only in bundles; dated
bundle dirs must carry an index.md; 5MB/file cap under docs/ and
experiments/) and requires a valid `status:` on every staged
`docs/proposals/*.md`. Commit-msg rejects a message claiming
to fix a `docs/bugs/` file without deleting it in that commit. Pre-push
rejects any push to `main` missing landing markers (leftover
`docs/tasks/branch-*.md`, unarchived `openspec/changes/*/`).

Two informational layers sit above the git hooks: `scripts/doc-status.sh`
prints one drift line (journal age, stale tasks, bugs, desk, semantic
index, dangling `— details:`/`Revises` pointers, experiments with ≥2 runs
newer than their README — `unreflected-runs`, untriaged run outputs in
the store, orphaned store dirs) on every SessionStart
event — startup, resume, clear, and compact, so long auto-compacting
sessions keep seeing it — and a plugin-level PreToolUse lint runs one
batched Haiku judgment check when a `git commit` touches
journal/notes/bugs/tasks files or `experiments/*/notebook/` (self-
containedness, real summaries, actionable bugs, evidence-grade notebook
entries; a new run that contradicts its experiment README's verdict while
the README goes untouched is flagged): violations block that one attempt
with reasons, an unchanged retry proceeds (warn-once), `LENORE_NO_LINT=1`
disables. The pre-commit hook additionally gates conclusions (flipping an
experiment README's `status` to concluded/shelved — or a candidate
system's to adopted/retired — requires a real verdict,
a concluded date, and a journal entry in the same commit), quarantines
experiments (no import-shaped references or symlinks into `experiments/`
from production code — promotion goes by copy + a `PROMOTIONS.md` entry;
intra-experiments reuse via `uses:` is exempt; the data symlink is
blessed only when it points exactly at its own store dir; the hook also
warns on an experiment-dir rename that would strand its store dir),
keeps `experiments/PROMOTIONS.md` append-only,
and guides merge conflicts on same-named dated notes/bugs: default is
both committed versions survive (one refiled under a new dated name — the
hook prints the exact command); a deliberate drop of a read-and-judged
junk twin proceeds on an unchanged retry (warn-once). The judgment lint
has two possible homes, chosen per repo: the agent-harness hook (default
for Claude/Codex users — manual commits stay model-free) or git
pre-commit itself (`git config lenore.commitlint true` — for users who
commit manually or use other harnesses; `LENORE_COMMIT_LINT=1/0`
overrides per command). An ok-hash handshake makes the two homes mutually
exclusive per commit, so nothing is ever judged twice. No
scheduled jobs; doc maintenance is event-driven only.

## Settled decisions — do not re-litigate

- No `decisions.md`, no ADRs, no entry IDs, no supersession markers.
- No entry IDs extends to the spine (corrected 2026-08-20): caveats and
  premises briefly shipped with C1/P1-style stable IDs and the user
  killed them same-day — an ID scheme anywhere teaches agents to number,
  renumber, and cross-reference by ID (the ADR latch pattern). Entries
  get short descriptive slug names and are cited by name in plain words.
- No maintained indexes or `_generated/` files — `ls`/`grep`/`browse.py`
  compute everything live.
- No inbox, no librarian subagent — capture is direct, in flow.
- No dedicated docs worktree — unique dated files already kill conflicts.
- No `state.md` — task content → `project.md`; architecture →
  `docs/system/` chapters; history → backfilled journal.
- No `docs/reference/` — retired 2026-08-20: tools/procedures →
  playbook; internal explanations → system chapters; dated research →
  notes. The closed-layout hook rejects it.
- Proposals are the ONE revisable dated class — everything else dated is
  immutable. The status field is what makes revisability safe; never
  extend it to notes or journal.
- No new docs/ homes, ever, without a design round — the closed-layout
  hook enforces the set; "this content is special" routes to an existing
  home or a dated note.
- No scheduled/cron jobs for doc maintenance.
- No pin-until / frontmatter expiry on desk links — the 14-day mtime check
  covers it.
- No obsolete-markers on notes — deletion, sinking, and "notes aren't
  authority" cover staleness without a status field. A correcting note
  says "Revises <file>" in its body (a forward reference in prose, not a
  marker on the old note).
- No structured capture format for doc bodies — structure lives in the
  envelope (filenames, line-1 summary, shape caps, front-matter keys the
  tools read); bodies stay free prose. No JSON/YAML schemas, no
  format-rejection of content.
- No task-per-file, no generated task index — `project.md` is
  simultaneously the queue and its index; files are for things with
  independent lifecycles (bugs), lines for things reviewed together.
- No tool-provenance tracking — hooks enforce what files contain, never
  which tool wrote them.
- No monolithic JOURNAL.md/TASKS.md — one file per entry, always.
- Architecture lives in `docs/system/` chapters (living, hook-limited,
  updated in the falsifying commit) — this supersedes the earlier "no
  standing ARCHITECTURE.md, dated snapshots only" rule (2026-08-20
  taxonomy adoption; the workflow-fit review showed cross-cutting current
  truth needs a maintained home, not snapshots).
- Experiments: no notebook.md file (the notebook is the `notebook/` dir —
  `cat notebook/*.md` is the derived single-scroll view); no `results/`
  or `artifacts/` dirs (keepers are promoted into `notebook/`, named
  after their run); no run-index table in the README (derived, never
  hand-kept); no narrative in the README (truth only); no dates or HHMM
  in run names (dates stay on experiment dirs); a sweep is ONE run with
  per-point subdirs; outputs never split by size/extension at write time
  — everything to the store's `out/<runid>/`, curation only at cleanup
  rounds; store inside the repo at `/data/` (no external per-project
  dir, no `data/data/` nesting); no DVC/MLflow/W&B; no
  `experiments/_shared/` — third consumer means promote. Candidate
  systems (`kind: candidate-system`) are exempt from dated names,
  runNNN structure, and the store trio — their required shape is the
  document map + Dead ends register + terminal verdict instead.

## Reference index

- `references/doc-guidance.md` — full per-directory rules (journal, notes,
  reference, tasks, bugs, experiments' three zones, desk incl.
  remove-vs-delete, tmp, scripts, openspec). Read when the trigger table
  above isn't enough detail.
- `references/experiment-templates.md` — the experiment README and
  notebook-entry templates with per-section rationale, filled examples,
  and the rejected-alternatives list.
- `references/semantic-search-setup.md` — semantic search install,
  chunking behavior and writing guidance, query phrasing, index
  lifecycle, troubleshooting.
- `references/routing.md` — the question→location table plus when to
  search notes before starting new work.
- `references/rules-tier1.md` / `references/rules-tier0.md` — the exact
  `CLAUDE.md` rules blocks to paste into a repo (install payloads, paste
  verbatim, don't paraphrase).
- `templates/` — working `.githooks/` (all four hooks), `scripts/browse.py`,
  `scripts/doc-status.sh`, `scripts/lenore-docs.py`, `scripts/docs-search.py`,
  `scripts/doc-lint.sh` (plugin-level commit-time judgment lint),
  `docs/CLAUDE.md`, `.gitignore` snippet, `codex-hooks.json`.
- `agents/doc-lint-judge.md` — the Haiku judgment prompt behind the
  commit-time lint, shipped as an invocable agent; `doc-lint.sh` sources
  its prompt from this file, so there is exactly one copy to tune.
- `tests/doc-lint/` — regression suite for the judge prompt (26 cases,
  runner, provenance README). Run it before changing the prompt or the
  lint script; a `borderline_*` case turning BLOCK means the change is
  wrong.
- `/lenore-doc-system:setup` — propose-then-apply installer, including
  migration of legacy tracking docs.
- `/lenore-doc-system:land` — the landing flow.
- `/lenore-doc-system:desk` — desk review (list, renew-or-drop stale pins,
  suggestions). Interactive only.
- `/lenore-doc-system:doc-cleanup` — hygiene pass over Someday, stale
  branch-task files, and stale bugs; confirmed diffs only. Interactive only.
