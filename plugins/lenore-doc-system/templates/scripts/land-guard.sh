#!/usr/bin/env bash
# Lenore doc system — landing-flow reminder (PreToolUse hook on Bash).
# Fires when the agent is about to run `git merge <ref>` while ON the
# default branch. Skills are not reliable at auto-triggering the landing
# flow, so this hook is the deterministic backstop: if the merged ref's
# tree still contains its branch task file (docs/tasks/branch-<slug>.md
# — the land flow deletes it BEFORE merging), the flow clearly has not
# run, and the merge attempt is blocked once with a reminder to run
# /lenore-doc-system:land. Re-running the identical command proceeds
# (warn-once: a deliberate bare merge costs one retry, never a standoff
# — and the pre-push landing gate still checks the markers later).
# No branch task file in the ref → silent pass: either the land flow
# already cleaned up, or the branch was never tracked — no way to tell,
# and false positives are worse than misses.
# Entirely deterministic — no model call. LENORE_NO_MERGE_GUARD=1 skips.
set -uo pipefail

[ "${LENORE_NO_MERGE_GUARD:-0}" = "1" ] && exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("command", ""))
except Exception:
    pass
' 2>/dev/null) || exit 0

# Only act on `git merge` (compound commands included); ignore
# `git merge --abort/--continue/--quit` (mid-merge plumbing, not a new merge).
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+([^[:space:]]+[[:space:]]+)*merge([[:space:]]|$)' || exit 0
printf '%s' "$cmd" | grep -qE 'merge[[:space:]]+(--abort|--continue|--quit)' && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f docs/CLAUDE.md ] || exit 0   # only repos running this doc system

# Any merge destination counts: a branch whose task file is still open
# must be closed out before its work is integrated ANYWHERE — main or
# another branch. (Merging main INTO a feature branch passes naturally:
# main's tree carries no open branch task file for itself.)
current=$(git branch --show-current 2>/dev/null)

# The merged ref: last non-flag word of the merge invocation.
ref=$(printf '%s' "$cmd" | sed -E 's/.*git[[:space:]]+([^[:space:]]+[[:space:]]+)*merge[[:space:]]+//; s/[;&|].*$//' \
      | tr ' ' '\n' | grep -v '^-' | grep -v '^$' | tail -1)
[ -n "$ref" ] || exit 0
git rev-parse --verify --quiet "$ref^{commit}" >/dev/null || exit 0

# The land flow deletes docs/tasks/branch-<slug>.md before merging; an
# open one in the merged ref's tree that names a branch pointing at that
# ref means the flow has not run. (Matching via --points-at also covers
# merging by sha or by remote-tracking name, where the ref string itself
# would not slug-match the task file.)
open_task=""
while IFS= read -r f; do
  s="${f#docs/tasks/branch-}"; s="${s%.md}"
  if git branch --points-at "$ref" --format='%(refname:short)' 2>/dev/null \
       | sed 's|/|-|g' | grep -qxF "$s"; then
    open_task="$f"
    break
  fi
done < <(git ls-tree -r --name-only "$ref" -- docs/tasks/ 2>/dev/null | grep '^docs/tasks/branch-' || true)
[ -n "$open_task" ] || exit 0

# Warn-once: an identical retry passes.
gitdir=$(git rev-parse --git-dir)
stamp="${gitdir}/lenore-land-warned"
sig=$(git rev-parse "$ref")
if [ -f "$stamp" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$sig" ]; then
  # Leave the stamp: the git-layer pre-merge-commit hook (which also
  # runs this check, for manual merges) consumes and removes it, so the
  # one warning is shared across both layers instead of doubling.
  exit 0
fi
printf '%s' "$sig" > "$stamp"
echo "lenore: merging '${ref}' into '${current:-$(git rev-parse --short HEAD)}', but its branch task file (${open_task}) still exists — the landing flow has not run. Run /lenore-doc-system:land (Codex: follow the landing flow in the lenore-doc-setup skill) instead of a bare merge: closing journal entry, doc review, task cleanup, THEN the merge. To merge anyway, re-run the same command." >&2
exit 2
