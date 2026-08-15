---
description: Run the landing flow — close out and merge the current branch into main
argument-hint: "[--autonomous]"
allowed-tools: Bash(git:*), Bash(rm:*), Read, Write, Edit, Glob, Grep
---

Run the Lenore doc system's landing flow (the `doc-system` skill describes what counts as a landing and what doesn't)
for the current branch. A landing is a merge into main, or an explicit
decision to abandon the branch. Both paths run this flow; the merge (or the
abandonment) is always the **last** step.

## 0. Preconditions

- Verify the current branch is **not** the default branch. Detect the
  default branch via `git symbolic-ref refs/remotes/origin/HEAD`
  (strip the `refs/remotes/origin/` prefix); if that's unset, fall back to
  `main` if it exists, else `master`. If the current branch is the default
  branch, stop — there is nothing to land.
- **Branch task slug convention:** the branch's task file is
  `docs/tasks/branch-<slug>.md`, where `<slug>` is the branch name with
  every `/` replaced by `-` (e.g. branch `feature/x` →
  `docs/tasks/branch-feature-x.md`). Use this slug everywhere below that
  this doc says "the branch task file."
- **Worktrees:** if the default branch is checked out in a *different*
  worktree than the one you're running in (check with `git worktree
  list`), run the merge (step 5) in that other worktree — `cd` there for
  the merge command, or use `git -C <path>`. Do not attempt to `git
  checkout` the default branch in the current (feature) worktree; that
  fails or corrupts the feature branch's checkout if the default branch is
  already checked out elsewhere.
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

Write one `docs/journal/YYYY-MM-DD-HHMM-topic.md` entry following the journal
shape rules (line 1 = one sentence, ≤10 lines / 150 words, no headers or
bullets, cite commit hashes), opening with "landing <branch>: …" — e.g.
"landing feature/x: after N days; the arc was A→B→C" — or, if abandoning,
"landing feature/x: abandoned because...". Writing this entry before the
merge (step 5) is fine and intentional (it's a plan-to-land statement);
if the merge/push subsequently fails, see step 5's recovery rule — do not
edit this entry after the fact. If autonomous mode skipped the desk walk
(step 4), say so explicitly in this entry: "desk not reviewed."

## 3. Archive the openspec change folder

Run `openspec archive <name>` — the CLI also performs the spec update
and writes to `openspec/changes/archive/<date>-<name>/`. Only if the CLI
is absent, hand-move the folder there and sync `openspec/specs/`
yourself. Add a one-line note if the change was dropped rather than
completed.

## 4. Walk the branch task file and the desk

**If interactive:**

- Open `docs/tasks/branch-<slug>.md`. For each open item, ask the user
  whether it graduates to `docs/tasks/project.md` (Next or Someday) or is
  dropped. Apply only what's confirmed, then delete the branch file.
- Walk `docs/desk/`: for each symlink, default is unpin (remove the
  symlink with `rm`, not `git rm` — desk pins are gitignored so git does
  not track them); if the user says keep, add one pointer line to
  `docs/tasks/project.md` instead, then remove the symlink. Clear the desk
  completely by the end of this step.

**If autonomous** (skip all questions in this step):

- Move every open item in `docs/tasks/branch-<slug>.md` verbatim into
  `docs/tasks/project.md` under `## Next`, each tagged
  `(unreviewed, from branch <branch>)`. Delete the branch file.
- Leave every desk pin exactly as-is — do not unpin, do not graduate, do
  not touch `docs/desk/`.
- The closing journal entry (step 2) must note "desk not reviewed."

## 5. Merge — last step

- Confirm the landing markers now hold: no `docs/tasks/branch-*.md` for
  this branch, no unarchived `openspec/changes/*/` folders.
- Merge the branch into the default branch (detected in step 0) using the
  repo's normal merge method, in the worktree where the default branch is
  checked out. **Never pass `--no-verify` to skip hooks** — if the
  pre-push landing gate rejects the push, that means a marker is still
  missing; fix it and retry, do not bypass.
- Clean up the branch's worktree if one was used for this branch
  (`git worktree remove`), after the merge succeeds.
- **Recovery if the merge or push fails:** the closing journal entry
  (step 2) was already written before this step; once committed it is
  immutable and cannot be edited or deleted. If the merge or push does not complete
  successfully, append a **new** `docs/journal/` entry noting that the
  landing described in the earlier entry did not complete (what failed,
  and the branch's current state), so the journal stays a truthful
  record. Do not retroactively make the earlier entry's claim true by
  force-completing an unsafe merge.

## Notes

- If the branch is being **abandoned** rather than merged, skip step 5's
  merge (there is nothing to merge) but still run steps 1-4 so the closing
  journal entry and task/desk cleanup happen, then leave the branch as-is
  or delete it per the user's instruction.
- This command never invents landing markers to satisfy the pre-push hook
  faster — the hook checks structural facts (files present or absent), and
  the point is that those facts are true, not just declared true.
