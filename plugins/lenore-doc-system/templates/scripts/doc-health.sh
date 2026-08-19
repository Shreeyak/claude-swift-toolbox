#!/usr/bin/env bash
# usage: scripts/doc-health.sh [&]   (run from the repo root; backgroundable)
# what it does: runs the doc-health audit headlessly for harnesses without
# the Agent tool (Codex, plain terminal). Creates a dedicated worktree +
# branch doc-health-YYYY-MM-DD from HEAD, feeds the doc-health-auditor
# prompt (plus the hygiene rulebook) to a headless agent backend —
# codex exec (workspace-write, cd'd into the worktree) when available,
# else claude -p on Sonnet — and prints the branch name and the agent's
# closing report. Never touches the current checkout; never merges.
set -uo pipefail

[ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1 || { echo "doc-health: not a git repo" >&2; exit 1; }
grep -q 'docs-system:' CLAUDE.md 2>/dev/null || { echo "doc-health: no docs-system: marker in CLAUDE.md" >&2; exit 1; }

base_sha=$(git rev-parse HEAD)
day=$(date +%Y-%m-%d)
branch="doc-health-${day}"
wt=".claude/worktrees/${branch}"

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo "doc-health: branch ${branch} already exists — merge or delete it first" >&2
  exit 1
fi
mkdir -p .claude/worktrees
git worktree add "$wt" -b "$branch" HEAD >/dev/null 2>&1 || { echo "doc-health: worktree add failed" >&2; exit 1; }

# Locate the auditor prompt + rulebook: repo copies first, then the plugin.
find_file() {
  for c in "$@"; do [ -f "$c" ] && { echo "$c"; return 0; }; done
  return 1
}
rules=$(find_file scripts/doc-hygiene-rules.md \
  "${CLAUDE_PLUGIN_ROOT:-/nonexistent}/skills/doc-system/references/doc-hygiene-rules.md") || {
  echo "doc-health: doc-hygiene-rules.md not found (run setup to copy it into scripts/)" >&2
  git worktree remove --force "$wt" >/dev/null 2>&1; git branch -D "$branch" >/dev/null 2>&1
  exit 1
}
auditor=$(find_file scripts/doc-health-auditor.md \
  "${CLAUDE_PLUGIN_ROOT:-/nonexistent}/agents/doc-health-auditor.md") || {
  echo "doc-health: doc-health-auditor.md not found (run setup to copy it into scripts/)" >&2
  git worktree remove --force "$wt" >/dev/null 2>&1; git branch -D "$branch" >/dev/null 2>&1
  exit 1
}

# Strip the agent front-matter; inline the rulebook so the headless agent
# needs no path resolution.
prompt=$(sed '1{/^---$/!q;};1,/^---$/d' "$auditor")
launch=$(printf 'You are already inside your dedicated worktree on branch %s (base SHA %s). The rulebook is inlined below — do not go looking for it.\n\n%s\n\n=== RULEBOOK: doc-hygiene-rules.md ===\n%s\n' \
  "$branch" "$base_sha" "$prompt" "$(cat "$rules")")

echo "doc-health: auditing in ${wt} (branch ${branch}, base ${base_sha})"
if command -v codex >/dev/null 2>&1; then
  printf '%s' "$launch" | codex exec --cd "$wt" -s workspace-write \
    -c model_reasoning_effort="medium" --color never --skip-git-repo-check - \
    </dev/null || true
elif command -v claude >/dev/null 2>&1; then
  ( cd "$wt" && printf '%s' "$launch" | claude -p --model sonnet \
      --permission-mode acceptEdits 2>/dev/null ) || true
else
  echo "doc-health: no headless backend (codex or claude) on PATH" >&2
  git worktree remove --force "$wt" >/dev/null 2>&1; git branch -D "$branch" >/dev/null 2>&1
  exit 1
fi

echo "doc-health: done — review with: git diff ${base_sha}..${branch}; merge when satisfied; then git worktree remove ${wt}"
