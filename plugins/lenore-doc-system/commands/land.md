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
`openspec/changes/<name>/` folder describes work that's done, apply that
folder's APPROVED deltas to the specs now, in the same commit style as the
rest of the branch.

**Divergence protocol:** spec sync applies the approved deltas — it never
rewrites specs to match whatever was built. If what the branch built
diverges from what the change folder planned, STOP and raise it to the
user with the details (the spec/delta line vs the built behavior, side by
side). The user decides: amend the change folder (re-approving the new
shape) or fix the code. Silently editing specs to match the code is the
wrong signal — it would record "built as planned" when it wasn't.

## 1b. Landing doc review

Spawn the branch-diff doc reviewer via the Agent tool: `subagent_type:
"lenore-doc-system:landing-doc-reviewer"` (it pins its own model — do not
review inline), telling it the merge base and branch head. It checks the
branch's doc files and docstrings against the hygiene rulebook (invented
IDs, opaque names, history narration, reviewer-directed comments) and
cross-checks new claims against untouched living docs. Fix what it flags
(same warn-once posture as the commit lint: a finding you judge wrong
after reading it can be waived — note why in the closing journal entry if
you waive anything). If the agent type is unavailable (Codex, plugin not
installed), read `scripts/doc-hygiene-rules.md` and do this review
yourself before proceeding.

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

Check the change folder's `tasks.md` first:

- **All tasks checked** → archive automatically: run
  `openspec archive <name>` (the CLI also performs the spec update and
  writes to `openspec/changes/archive/<date>-<name>/`; only if the CLI is
  absent, hand-move the folder and sync `openspec/specs/` yourself).
  Mention the archive in your landing summary — no question needed.
- **A few tasks left pending** (e.g. live device verification) → never
  auto-archive with unchecked boxes. Ask the user: (a) defer the pending
  tasks with a pointer — move them to `docs/tasks/project.md` (or the
  closing journal entry) naming the change folder, then archive as
  partially adopted with a one-line note saying what's deferred; or
  (b) keep the branch open and don't land yet.
- **Dropped rather than completed** → archive with a one-line note saying
  why.

## 4. Walk the branch task file and the desk

**If interactive:**

- If the branch task file has a non-empty `## Stakeholder notes`
  section, offer to compile the stakeholder brief (`/brief`) now,
  before the file is disposed. Declining is fine — the lines die with
  the task file. Never gates.
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
  `(unreviewed, from branch <branch>)`. If `## Stakeholder notes` is
  non-empty, move those lines the same way, tagged
  `(stakeholder notes, run /brief)` — never compile the brief
  autonomously; stakeholder wording needs the user present. Delete the
  branch file.
- Leave every desk pin exactly as-is — do not unpin, do not graduate, do
  not touch `docs/desk/`.
- The closing journal entry (step 2) must note "desk not reviewed."

## 4b. Reverse-drift sync review — after cleanup, before the merge

This is the mirror of step 1b: not "are the branch's new docs sound?"
but "did the branch's CODE changes falsify existing current-truth docs?"
It runs here — after spec sync, archive, and task cleanup — so it sees
the final pre-merge tree.

- Run the deterministic collector:
  `scripts/truth-candidates.sh <merge-base> <head>`. If it reports zero
  candidates AND the repo has no `.lenore/embeddings/` index, skip the
  reviewer entirely and note "sync-check: no candidates" in the closing
  journal entry.
- Otherwise spawn the sync reviewer via the Agent tool: `subagent_type:
  "lenore-doc-system:code-doc-sync-reviewer"` (it pins its own model —
  do not review inline), handing it the merge base, head, and the
  manifest. The shared contract is
  `references/reverse-drift-check.md` in the doc-system skill
  (repo fallback: `scripts/reverse-drift-check.md`). If the agent type
  is unavailable (Codex, plugin not installed), run the script and apply
  the contract yourself in-session.
- **Save the reviewer's reply verbatim as
  `docs/notes/YYYY-MM-DD-landing-<slug>-sync-report.md`** — it is
  written as that report (verdict line, metrics line, findings,
  per-candidate verdicts, coverage-gap recommendations, named
  overflow). Commit it with the landing. Reference it from the closing
  journal entry (step 2 may already be written — if so, the report
  filename is deterministic, so the entry can cite it in advance; if
  the entry didn't, do not edit it — the report is discoverable by its
  dated name).
- **Gate (armed from the first landing):** a `finding` — four-part
  evidence: doc line, quoted claim, code line, stated contradiction —
  blocks this landing until the doc is fixed on the branch or the
  finding is waived. A waiver names the claim, evidence, and reason in
  the closing journal entry. `clear`/`inconclusive`/coverage-gap
  recommendations never gate.
- **Coverage-gap recommendations** (changed files with no living-doc
  home): apply them directly — add the docstrings now, on the branch,
  before merging. Additive docstring edits need no user approval.
  Write them concern-first in design-doc vocabulary, then the
  mechanics — a mechanics-only docstring stays invisible to the next
  landing's semantic channel.

## 5. Merge — last step

- Confirm the landing markers now hold: no `docs/tasks/branch-*.md` for
  this branch, no unarchived `openspec/changes/*/` folders.
- Merge the branch into the default branch (detected in step 0) using the
  repo's normal merge method, in the worktree where the default branch is
  checked out. **Never pass `--no-verify` to skip hooks** — if the
  pre-push landing gate rejects the push, that means a marker is still
  missing; fix it and retry, do not bypass.
- The landing guard (agent hook + `pre-merge-commit`) blocks any merge of
  a branch whose `docs/tasks/branch-<slug>.md` still exists. Because this
  flow deletes that file in the steps above, its own merge passes the
  guard silently — if the guard fires here, a step above was skipped: go
  fix it, never re-run the merge to bypass. Repos set `merge.ff false`,
  so the merge creating a merge commit is expected, not an error.
- Landing into a non-default integration branch (stacked branches) runs
  this same flow with that branch as the merge target — the guard checks
  merges into every branch, and an open branch task file must be closed
  out before its work is integrated anywhere.
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
