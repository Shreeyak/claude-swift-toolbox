---
name: dryad
description: Use this skill whenever untangling git branch topology in a repo with many branches or worktrees — finding a branch's parent branch, where it forked from, a safe merge order, or which worktree a branch is checked out in. Trigger phrases include "parent branch", "where did this branch fork from", "merge order", "which worktree is X", "untangle branches", "branch forest". The `dryad` CLI is the canonical path for ALL of this — do not hand-roll `git merge-base` / `--fork-point` spelunking; its parent inference is a heuristic (closest fork wins, cycle-guarded) that agents should trust, not re-derive.
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
| A safe order to merge branches (parents before children) | `dryad merge-order [--onto main]` |
| A visual graph | `dryad gui` |
| zsh tab completion | `dryad completion` |

All subcommands accept `--repo <path>` (default: cwd) and `--json`
(explicit nulls for absent fields, e.g. a root branch's `parent`/`forkSha`
are `null`, never omitted).

## Rules for agents

- **Trust `dryad parent`'s inference; do not re-derive it.** It picks the
  closest fork point across the whole branch forest and is cycle-guarded.
  Raw `git merge-base` (or `--fork-point`) on two branches picked by hand
  does not reproduce this and can pick the wrong ancestor in a repo with
  many interleaved branches.
- **Exit codes are the API**: 0 ok, 1 unknown branch (stderr prints a
  hint listing known branches — read it instead of guessing spellings).
- **No ANSI when piped.** Output is plain text/JSON when stdout isn't a
  TTY — safe to pipe straight into `python3 -m json.tool`, `jq`, etc.
- **`dryad tree`'s `[wt: <dir>]` / `+N` annotations** show which branches
  have a live worktree and how far ahead of their fork they are — read
  these instead of shelling out to `git worktree list` and cross-referencing
  yourself.
- **Performance**: on a repo with very many branches this is O(N²)
  merge-base computation and can take tens of seconds. That's expected and
  fine for agent use — don't kill and retry it as if it hung.
