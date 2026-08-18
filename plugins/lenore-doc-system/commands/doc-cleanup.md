---
description: Doc-hygiene review — propose prunes for Someday, stale branch-task files, and stale bugs as diffs to confirm; catch-up journal entry if the gap warrants
allowed-tools: Bash(git:*), Bash(ls:*), Bash(rm:*), Bash(find:*), Bash(du:*), Bash(touch:*), Bash(mv:*), Bash(cp:*), Read, Write, Edit, Glob, Grep
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

## 5. Experiment store triage

Work the store (`data/experiments/`), experiment by experiment, sizes
first (`du -sh data/experiments/*/`). The default path is safe — nothing
here was ever auto-deleted — so this pass is where judgment happens:

- **Per-run triage.** For each `out/<runid>/` dir not yet triaged (newer
  than the experiment's `.lenore-triaged` marker, or all if no marker),
  read the matching `notebook/<runid>.md` entry and decide with the user:
  **delete** (question answered, bytes worthless), **keep** (still
  comparing against it), or **promote** (copy the few files that matter
  into `notebook/`, named after the run — `runNNN-slug-grid.csv` — then
  delete or keep the rest). An out/ dir with **no** notebook entry gets
  flagged: either it was noise (delete) or the record was never written
  (write it now if the context survives). After the walk, `touch
  data/experiments/<exp>/.lenore-triaged` — that resets the status line's
  `untriaged-runs` counter.
- **Concluded experiments.** Delete their `regen/` outright (rebuildable
  by definition — verify the README's Data section records the rebuild
  command first; if it doesn't, flag instead of deleting) and their
  `.venv/` / `vendor/` / `__pycache__` dirs. *Suggest* stale `keep/`
  deletions — never delete `keep/` without explicit per-item confirmation.
- **Orphans.** A `data/experiments/<name>` with no `experiments/<name>`
  in git. Before proposing deletion, check for a rename (a similarly
  named experiment dir) — if found, propose `mv` instead. Also grep
  `uses:` lines and `../<name>` references across `experiments/*` before
  suggesting deletion of any experiment dir itself — a dir someone
  depends on is flagged, not removed.
- **Misfiled workspaces.** An `experiments/*/` whose README carries no
  question/status shape is not an experiment — suggest relocation to the
  normal repo structure.
- **Over-promoted notebooks.** A `notebook/` ballooning with artifacts
  (dozens of files, images dominating) signals promotion doing the
  store's job — propose demoting the excess.

Deletions inside the store are `rm` of gitignored files (no git surface)
but still shown and confirmed per experiment. Promoted artifacts are
ordinary committed files — they go into the cleanup commit.

## 6. Catch-up journal entry

If the status line shows a large gap (last entry many days / many commits
ago), offer to write **one** catch-up entry summarizing the arc from
`git log` since the last entry — double the normal budget (~20 lines),
first line still one sentence. Never back-fill multiple entries.

## Notes

- This command deletes only what the doctrine already marks disposable:
  task files, bug files, Someday lines, and store bytes after triage.
  Notes are deleted only if the user names them; journal and notebook
  entries, never.
- Commit the confirmed changes as one cleanup commit (the pre-commit
  hook will reject anything that oversteps).
- Skippable for months without damage — say so if the user asks whether
  they're behind.
