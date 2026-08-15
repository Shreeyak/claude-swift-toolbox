# Question routing and search triggers

Read when answering a "where is X" or "have we tried X before" question,
or deciding whether to search `docs/notes/` before starting new work.

## Who answers which question

| You're asked… | Read… |
|---|---|
| "Why is the code shaped like this?" | Recent `docs/journal/` files (`ls` is the index), then the relevant spec; cited hashes for code detail |
| "What does feature X actually do today?" | `openspec/specs/<x>/` |
| "What's the overall architecture?" | Newest architecture note in `docs/notes/` — or generate a fresh one, stamped with the source commit |
| "What was I going to do next?" | `docs/tasks/` + open `openspec/changes/` folders |
| "What's broken right now?" | `ls docs/bugs/` — always the live list; fixed bugs are gone (their record is the fix commit) |
| "Did we ever try Y? What happened?" | `grep verdict: experiments/*/README.md`, then that README; `runs/` to reproduce |
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

## Why an outdated note is never a trap

There is deliberately no "obsolete" tag, status field, or superseded
marker on notes. Three mechanisms cover it instead: a note that turned out
to be junk gets deleted (notes are deletable — see `doc-classes.md`'s desk
section for the deletion policy); a note that's merely old sinks down the
newest-first `browse.py` listing; a note that's *wrong* misleads nobody,
because notes are never authority — the routing table above sends every
"what's true now" question to specs, `CLAUDE.md`, and experiment READMEs,
so an outdated note is by definition historical context, not a trap.
