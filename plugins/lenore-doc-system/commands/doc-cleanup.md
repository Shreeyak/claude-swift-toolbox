---
description: Doc-hygiene review — propose prunes for Someday, stale branch-task files, and stale bugs as diffs to confirm; catch-up journal entry if the gap warrants
allowed-tools: Bash(git:*), Bash(ls:*), Bash(rm:*), Bash(find:*), Read, Write, Edit, Glob, Grep
---

Run a documentation-hygiene pass. This is judgment work batched for when
the status line's numbers annoy the user — nothing here runs on a
schedule, and every deletion or prune is shown as a diff and applied only
after the user confirms. If the session is operating autonomously, do not
run this command; defer it to an interactive session.

Run `scripts/doc-status.sh` first (or `uv run scripts/browse.py --plain`)
to ground the pass in current numbers. Then work through the six areas,
skipping any with nothing to propose:

## 1. Someday prune

Read `docs/tasks/project.md` `## Someday`. Propose dropping entries that
are stale, superseded by shipped work (check specs and recent journal
entries), or duplicated elsewhere. Present as a single diff; apply what
the user confirms. If Someday has grown into a real backlog (dozens of
items), say so — that's the signal for an issue tracker, not a bigger
Someday.

## 2. Stale branch-task files

For each `docs/tasks/branch-*.md`: if its branch no longer exists (the
status line flags these as `stale-task:`), or has had no commits in 14+
days, propose disposal — each open item either graduates to `project.md`
(Next or Someday, user's call) or is dropped, then the file is deleted.
Never dispose of the current branch's own task file.

## 3. Stale bug triage

For each `docs/bugs/*.md` older than ~30 days, ask: still real? Fixed
bugs should have been deleted in their fix commit — if one was fixed but
the file lingers, delete it now (cite the fixing commit in the message).
Still-real bugs stay; optionally refresh the repro line if the user
confirms new info. Bug files are deletable by design; this never touches
journal entries or run records.

## 4. Task-entry lint (the stranger test)

Read every entry under `## Next` and `## Someday` in
`docs/tasks/project.md` and ask of each: could a competent developer act
on this using only the repo — are the files, commits, datasets, and
parameters it refers to locatable from what's written? For each entry
that fails (session shorthand like "the fix", "the sweep", bare
codenames), propose a rewrite to the user — they are the one context
source that persists; never invent specifics you don't actually know.
If an entry can't be reconstructed even with the user's help, propose
dropping it: a task nobody can decode is already lost. The commit-time
drift lint catches most of these at write time; this pass sweeps up what
predates it or slipped through.

## 5. Experiment data hygiene

For each `experiments/*/`, report the disk size of `data/` and `out/`
(`du -sh`). For experiments whose README `status:` is concluded or
shelved, propose deleting regenerable data — anything whose README
records a regeneration command or download source. Never propose deleting
data with no recorded way back; instead flag it ("no regeneration command
recorded — add one to the README or keep the data"). Deletions are `rm`
of gitignored files (no git surface), applied only after the user
confirms each experiment.

## 6. Catch-up journal entry

If the status line shows a large gap (last entry many days / many commits
ago), offer to write **one** catch-up entry summarizing the arc from
`git log` since the last entry — double the normal budget (~20 lines),
first line still one sentence. Never back-fill multiple entries.

## Notes

- This command deletes only what the doctrine already marks disposable:
  task files, bug files, Someday lines. Notes are deleted only if the
  user names them; journal and runs, never.
- Commit the confirmed changes as one cleanup commit (the pre-commit
  hook will reject anything that oversteps).
- Skippable for months without damage — say so if the user asks whether
  they're behind.
