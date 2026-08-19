# Question routing and search triggers

Read when answering a "where is X" or "have we tried X before" question,
or deciding whether to search `docs/notes/` before starting new work.

## Who answers which question

| You're asked… | Read… |
|---|---|
| "Why is the code shaped like this?" | Recent `docs/journal/` files (`ls` is the index), then the relevant spec; cited hashes for code detail |
| "What does feature X actually do today?" | `openspec/specs/<x>/` |
| "What's the overall architecture / data flow / state model?" | `docs/system.md` (the hub map), then the named chapter in `docs/system/` |
| "What must every design respect?" | `docs/system/premises.md` — the numbered P\<n\> ground rules; mandatory before any design/proposal/experiment |
| "Where does the system fail / what are the known hazards?" | `docs/caveats.md` — named entries; read each entry's Validity ladder in order |
| "How do we do X / which tool for X?" | `docs/playbook.md` — procedures, evaluated tools (use-when + last-verified), adopted research conclusions |
| "What was designed but not built?" | `docs/proposals/` — front-matter `status:` says where each stands; `browse.py --plain` shows them with status |
| "What research have we done on X?" | `ls docs/notes/ \| grep research`, or semantic search; adopted conclusions are already in the playbook/system with pointers back |
| "What was I going to do next?" | `docs/tasks/` + open `openspec/changes/` folders |
| "What's broken right now?" | `ls docs/bugs/` — always the live list; fixed bugs are gone (their record is the fix commit) |
| "Did we ever try Y? What happened?" | `grep verdict: experiments/*/README.md`, then that README; `cat notebook/*.md` for the story, an entry's anchors to reproduce; check the README's Dead ends & ruled out before re-opening a thread |
| "What's happening on the other branches?" | Other `tasks/branch-*.md` files (sibling worktrees / `git show`) + newest journal entries |
| "How has this project evolved?" | `docs/journal/` in date order — the narrative by construction; experiments appear inline with verdicts |
| "What changed in the code last week?" | `git log` — commits are the changelog |

## When to search notes/experiments before writing

Notes stay cold during ordinary coding — searching them is by trigger, not
routine:

- Before drafting an openspec proposal or design: grep `docs/notes/` and
  experiment READMEs for the topic's keywords — has this been explored?
- When a question smells like it's been investigated before ("didn't we
  test X?").
- When a task entry in `docs/tasks/` points at a note by name.

Use `scripts/browse.py --plain` (or `--json`) for the live index instead of
raw `grep` when you want dates and summaries, not just matches.

## Subagent review output — what to save, where

Reviews (subagent, codex, human) produce transcripts; the doctrine saves
the knowledge, never the transcript. "History is what's committed"
already covers most of a review:

- **Findings that were fixed: save nothing.** The fix commits are the
  record. A list of fixed nitpicks duplicates git history and goes
  stale immediately.
- **Findings deliberately declined are the valuable part.** "Reviewer
  proposed X, rejected because Y" is what a future session will
  otherwise re-litigate. Write `docs/notes/YYYY-MM-DD-review-<topic>.md`:
  first line = one-sentence verdict, then only surviving findings and
  declined-with-reason items. Distilled, never the raw transcript.
- **Confirmed bugs not being fixed now** → one file each in
  `docs/bugs/`, deleted later in the fix commit.
- **A finding that changes the design** → into the openspec change or
  spec, not a review note; a note may point there in plain words.
- **Milestone reviews** (pre-release audit, multi-round hardening) earn
  a note even if everything was fixed — the verdict is the finding. If
  it changed project direction, also one `docs/journal/` entry.

Rule of thumb: raw subagent transcripts never enter `docs/`; a review
earns a note only if it holds a decision or an open item that outlives
the session.

## Why an outdated note is never a trap

There is deliberately no "obsolete" tag, status field, or superseded
marker on notes. Three mechanisms cover it instead: a note that turned out
to be junk gets deleted (notes are deletable — see `doc-guidance.md`'s desk
section for the deletion policy); a note that's merely old sinks down the
newest-first `browse.py` listing; a note that's *wrong* misleads nobody,
because notes are never authority — the routing table above sends every
"what's true now" question to specs, `CLAUDE.md`, the spine
(system/caveats/playbook), and experiment READMEs,
so an outdated note is by definition historical context, not a trap.

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
