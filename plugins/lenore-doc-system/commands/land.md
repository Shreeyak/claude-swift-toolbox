---
description: Run the landing flow — close out and merge the current branch into main
argument-hint: "[--autonomous]"
allowed-tools: Bash(git:*), Read, Write, Edit, Glob, Grep
---

Run the Lenore doc system's landing flow (see the `doc-system` skill §4)
for the current branch. A landing is a merge into main, or an explicit
decision to abandon the branch. Both paths run this flow; the merge (or the
abandonment) is always the **last** step.

## 0. Preconditions

- Verify the current branch is **not** `main`/`master`. If it is, stop —
  there is nothing to land.
- Determine whether this session is operating **autonomously** (the user
  earlier gave a standing instruction like "build this out, don't wait on
  me") or **interactively** (the user is present now). This determines
  whether steps 3 and 4 ask questions or default silently — see below.
  Do not infer autonomy from silence alone; only a standing instruction
  from earlier in the session counts.

## 1. Final spec sync

Make sure `openspec/specs/` reflects what actually landed — if the branch's
`openspec/changes/<name>/` folder describes work that's done, sync the spec
now, in the same commit style as the rest of the branch.

## 2. Closing journal entry

Write one `docs/journal/YYYY-MM-DD-HHMM-topic.md` entry following the §5
shape rules (line 1 = one sentence, ≤10 lines / 150 words, no headers or
bullets, cite commit hashes): "landed X after N days; the arc was A→B→C" —
or, if abandoning, why. If autonomous mode skipped the desk walk (step 4),
say so explicitly in this entry: "desk not reviewed."

## 3. Archive the openspec change folder

Move `openspec/changes/<name>/` to its archive location per the OpenSpec
workflow already in use in this repo, with a one-line note if it was
dropped rather than completed.

## 4. Walk the branch task file and the desk

**If interactive:**

- Open `docs/tasks/branch-<branch>.md`. For each open item, ask the user
  whether it graduates to `docs/tasks/project.md` (Next or Someday) or is
  dropped. Apply only what's confirmed, then delete the branch file.
- Walk `docs/desk/`: for each symlink, default is unpin (remove the
  symlink); if the user says keep, add one pointer line to
  `docs/tasks/project.md` instead, then remove the symlink. Clear the desk
  completely by the end of this step.

**If autonomous** (skip all questions in this step):

- Move every open item in `docs/tasks/branch-<branch>.md` verbatim into
  `docs/tasks/project.md` under `## Next`, each tagged
  `(unreviewed, from branch <branch>)`. Delete the branch file.
- Leave every desk pin exactly as-is — do not unpin, do not graduate, do
  not touch `docs/desk/`.
- The closing journal entry (step 2) must note "desk not reviewed."

## 5. Merge — last step

- Confirm the landing markers now hold: no `docs/tasks/branch-*.md` for
  this branch, no unarchived `openspec/changes/*/` folders.
- Merge the branch into main using the repo's normal merge method. **Never
  pass `--no-verify` to skip hooks** — if the pre-push landing gate rejects
  the push, that means a marker is still missing; fix it and retry, do not
  bypass.
- Clean up the branch's worktree if one was used for this branch
  (`git worktree remove`), after the merge succeeds.

## Notes

- If the branch is being **abandoned** rather than merged, skip step 5's
  merge (there is nothing to merge) but still run steps 1-4 so the closing
  journal entry and task/desk cleanup happen, then leave the branch as-is
  or delete it per the user's instruction.
- This command never invents landing markers to satisfy the pre-push hook
  faster — the hook checks structural facts (files present or absent), and
  the point is that those facts are true, not just declared true.
