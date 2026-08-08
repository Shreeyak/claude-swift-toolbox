---
name: dryad
description: Use this skill whenever untangling git branch topology in a repo with many branches or worktrees — finding a branch's parent branch, where it forked from, a safe merge order, which worktree a branch is checked out in, or which branches are already merged and safe to clean up. Trigger phrases include "parent branch", "where did this branch fork from", "merge order", "which worktree is X", "untangle branches", "branch forest", "which branches are merged". The `dryad` CLI is the canonical path for ALL of this — do not hand-roll `git merge-base` / `--fork-point` spelunking; its parent inference is a heuristic (closest fork wins, cycle-guarded) that agents should trust, not re-derive.
---

# dryad — git branch topology CLI

`dryad` infers branch parentage, prints the branch forest (with worktree
locations), and computes a safe parents-before-children merge order. Check
availability and full usage with `dryad --help` / `dryad help <subcommand>`
— that output is authoritative; this skill only routes you to the right
command.

If `dryad` is not on PATH, ask the human where the dryad repo lives.

## Command decision table

| You want | Run |
|---|---|
| A branch's parent + fork point | `dryad parent [<branch>]` (default: current branch) |
| The whole branch forest, with worktree paths | `dryad tree` |
| …including branches already merged into main | `dryad tree --all` |
| …plus branches pushed to `origin` but not checked out locally | `dryad tree --remote` (fetches) |
| A safe order to merge branches (parents before children) | `dryad merge-order [--onto main]` |
| Which files a branch changed since its fork point | `dryad files <branch> [--onto <base>]` |
| Whether a branch merges cleanly into a target | `dryad conflicts <branch> [--onto main]` |
| An AI summary of a branch's own work (spawns `claude -p`, haiku; cached) | `dryad summary <branch> [--refresh]` |
| A visual graph | `dryad gui` |
| zsh tab completion | `dryad completion` |

All subcommands accept `--repo <path>` (default: cwd) and `--json`.

## The `--json` contract

**Prefer `--json` over parsing the human output.** Every key names its own unit
and reference point, and every declared key is ALWAYS present — an absent value
is an explicit `null`, never an omitted key, so index in without guarding.

`dryad tree --json` emits nested forest nodes (same shape at every depth):

| key | meaning |
|---|---|
| `branch` | branch name |
| `parentBranch` | inferred parent; `null` for a root |
| `forkCommitSha` / `forkCommitShortSha` | merge-base with the parent; `null` for a root |
| `commitsAheadOfFork` | commits **this branch** added past the fork |
| `commitsParentAddedSinceFork` | commits the **parent** gained since the fork — *not* "behind main" |
| `linesAddedSinceFork` / `linesRemovedSinceFork` | diff size of the branch's own work; `null` with no fork |
| `mergedIntoTrunk` | tip is already contained in `main`/`master` |
| `tipCommittedAtEpochSeconds` | tip's committer timestamp — compute age yourself |
| `worktreePath` | absolute checkout path; `null` when not checked out |
| `children` | nested nodes |

`dryad parent --json` → `{branch, parentBranch, forkCommitSha,
forkCommitShortSha, commitsAheadOfFork}` — same names, same meanings.

`dryad files --json` → `{branch, baseCommitSha, baseIsEmptyTree, files:
[{gitStatusCode, path, previousPath}]}`. `gitStatusCode` is git's raw letter
(`M`, `A`, `R100`, …); `previousPath` is non-null only for renames/copies;
`baseIsEmptyTree` flags a root branch, where the diff is its whole history
rather than fork-scoped work.

`dryad conflicts --json` → `{branch, ontoBranch, mergesClean,
conflictedPaths}`. This is a **dry run** (`git merge-tree`) — `mergesClean`
describes the simulated merge, not any working tree, and nothing is merged.

`dryad summary --json` → `{branch, tipCommitSha, forkCommitSha,
servedFromCache, summaryText}`.

`dryad merge-order --json` → a JSON array of branch names, in order.

`dryad tree --remote --json` (note: `--remote` changes the shape, `--json` alone
never does) → `{forest, remoteBranches, remoteOriginConfigured}`. `forest` is the
same nested-node array as plain `dryad tree --json`. `remoteBranches` is an array
of branches present on `origin` but not checked out locally — always present, never
`null`, possibly empty — each entry `{branch, tipCommitSha, tipCommitShortSha,
tipCommittedAtEpochSeconds, commitSubject, authorName}`. `remoteOriginConfigured`
is a boolean distinguishing "no `origin` remote" (`false`) from "`origin`
configured but nothing is remote-only" (`true`, empty `remoteBranches`) — both
would otherwise look identical (empty). **`dryad tree --json` alone is unaffected
by any of this** — still exactly the plain forest array above, forever; only
passing `--remote` alongside `--json` changes the top-level shape.

## Reading `dryad tree`'s human output

Two metric columns: **tip age first** (`5d`, `21d` — live vs abandoned), then
the branch's own diff since its fork (`+964/-171`, abbreviated past 1k). That
size is a DIFF, not a commit count. Markers: `●` HEAD, `✎` uncommitted changes
in that branch's worktree, `✓` merged into main, `⌂` still occupies a worktree.

By default, branches whose whole subtree is merged into `main` are folded into a
`Merged into main (N)` line, and the `Worktrees` section lists only branches
still in the tree plus a `… N more on merged branches` count. `--all` expands
everything.

## Rules for agents

- **Trust `dryad parent`'s inference; do not re-derive it.** It picks the
  closest fork point across the whole branch forest and is cycle-guarded.
  Raw `git merge-base` (or `--fork-point`) on two branches picked by hand
  does not reproduce this and can pick the wrong ancestor in a repo with
  many interleaved branches.
- **A merged branch is never a second root.** If its tip is contained in
  `main`, dryad attaches it to the trunk with `mergedIntoTrunk: true` and null
  fork/ahead fields — those numbers would be degenerate, not missing.
- **Exit codes are the API**: 0 ok, 1 unknown branch (stderr prints a hint
  listing known branches — read it instead of guessing spellings), 2 usage.
  `conflicts` exits **0** even when it finds conflicts: the check ran, that's a
  result, not a CLI error. Read `mergesClean`.
- **No ANSI when piped.** Output is plain text/JSON when stdout isn't a
  TTY — safe to pipe straight into `python3 -m json.tool`, `jq`, etc.
- **Performance**: the whole commit graph is loaded once and every merge-base is
  computed in memory, so topology is sub-second even on large repos. `tree`
  additionally runs one `git status` per checked-out branch and one `git diff
  --shortstat` per branch, concurrently — a second or two on a repo with huge
  diffs. Expected; don't kill and retry as if it hung.
- **`--remote` is the one flag that touches the network.** Every other command
  and flag reads local git state only. `dryad tree --remote` runs
  `git fetch --prune origin` first — expect real network latency, and expect it
  to fail cleanly (exit 1, local tree still printed in human output; nothing
  printed in `--json`) with no network or no `origin` configured. Never pass
  `--remote` reflexively; only when you actually need to know what's on
  `origin` that isn't checked out locally.
