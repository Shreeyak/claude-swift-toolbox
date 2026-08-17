#!/usr/bin/env bash
# Lenore doc system — advisory drift lint (PreToolUse hook on Bash).
# Fires when the agent is about to run a `git commit`. Batches every new or
# modified docs/{journal,notes,bugs,tasks} and experiments/*/runs .md file
# (worktree vs HEAD — the
# commit command may stage as part of the same compound command, so the staged
# set can't be trusted yet) into ONE cheap-model call checking the JUDGMENT
# rules the deterministic git hooks can't (does line 1 actually summarize? is
# a task entry self-contained? does a bug file carry a repro?).
#
# On violations it blocks the commit attempt (exit 2 — stderr goes back to the
# agent) so the fix happens while the writing session still has the context;
# the files are not yet committed, so they are still editable. On OK, or on
# any error, it stays silent and lets the commit run (fail-open). Shape rules
# are NOT re-checked here — the git pre-commit hook owns those.
#
# Disable with LENORE_NO_LINT=1 (env, or anywhere in the command string).
# Judge backend: `claude` (Haiku) when available, else `codex exec`
# (gpt-5.6-terra, medium effort) — so the same hook works from either
# harness. Silently no-ops when neither CLI exists.
set -uo pipefail

[ "${LENORE_NO_LINT:-0}" = "1" ] && exit 0
command -v claude >/dev/null 2>&1 || command -v codex >/dev/null 2>&1 || exit 0

input=$(cat)

cmd=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("command", ""))
except Exception:
    pass
' 2>/dev/null) || exit 0

# Only act on git commit commands (compound commands included).
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+([^[:space:]]+[[:space:]]+)*commit([[:space:]]|$)' || exit 0
# Respect an explicit skip in the command itself.
printf '%s' "$cmd" | grep -q 'LENORE_NO_LINT=1' && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f docs/CLAUDE.md ] || exit 0   # only repos running this doc system

# New/modified doc files, worktree vs HEAD (covers add-and-commit compounds).
files=$(git status --porcelain -- 'docs/journal/*.md' 'docs/notes/*.md' 'docs/bugs/*.md' 'docs/tasks/*.md' 'experiments/*/runs/*.md' 2>/dev/null \
        | grep -E '^.?[AM?]' | sed 's/^...//' | sed 's/^"\(.*\)"$/\1/')
[ -n "$files" ] || exit 0

payload=""
count=0
run_exps=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  [ "$count" -gt 8 ] && break   # bound the batch; a mega-commit lints its first 8
  payload="${payload}
=== FILE: $f ===
$(cat "$f")
"
  case "$f" in
    experiments/*/runs/*.md)
      exp=${f%/runs/*}
      case "
$run_exps" in *"
$exp"*) ;; *) run_exps="${run_exps}${exp}
" ;; esac
      ;;
  esac
done <<< "$files"
[ -n "$payload" ] || exit 0

# For each experiment contributing a run file, append its README as CONTEXT
# (not linted itself) so the judge can catch a verdict the new run
# contradicts while the README goes untouched in this commit.
while IFS= read -r exp; do
  [ -n "$exp" ] || continue
  readme="$exp/README.md"
  [ -f "$readme" ] || continue
  if [ -n "$(git status --porcelain -- "$readme" 2>/dev/null)" ]; then
    state="also modified in this commit"
  else
    state="NOT touched in this commit"
  fi
  payload="${payload}
=== CONTEXT: $readme ($state) ===
$(cat "$readme")
"
done <<< "$run_exps"

# Warn-once: if this exact doc content was already flagged, let the retry
# through — a disputed judgment call costs one retry, never a standoff.
gitdir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
ack_file="$gitdir/lenore-lint-ack"
payload_hash=$(printf '%s' "$payload" | git hash-object --stdin 2>/dev/null || echo none)
if [ -f "$ack_file" ] && [ "$(cat "$ack_file" 2>/dev/null)" = "$payload_hash" ]; then
  rm -f "$ack_file"
  exit 0
fi

# The judge prompt is the shipped doc-lint-judge agent's body (single source
# of truth — tune the agent, the hook follows). Plugin root arrives as $1
# from hooks.json; CLAUDE_PLUGIN_ROOT is the fallback.
plugin_root="${1:-${CLAUDE_PLUGIN_ROOT:-}}"
agent_file=""
for cand in "$plugin_root/agents/doc-lint-judge.md" "$plugin_root/doc-lint-judge.md" "scripts/doc-lint-judge.md"; do
  [ -f "$cand" ] && { agent_file="$cand"; break; }
done
[ -n "$agent_file" ] || exit 0
prompt=$(sed '1{/^---$/!q;};1,/^---$/d' "$agent_file")
[ -n "$prompt" ] || exit 0

judge_label="haiku"
if command -v claude >/dev/null 2>&1; then
  verdict=$(printf '%s\n%s\n' "$prompt" "$payload" | claude -p --model claude-haiku-4-5-20251001 --max-turns 1 2>/dev/null) || exit 0
else
  judge_label="codex/terra"
  out=$(mktemp) || exit 0
  printf '%s\n%s\n' "$prompt" "$payload" \
    | codex exec --model gpt-5.6-terra -c model_reasoning_effort="medium" \
        -s read-only --ephemeral --color never --skip-git-repo-check \
        -o "$out" - >/dev/null 2>&1 || { rm -f "$out"; exit 0; }
  verdict=$(cat "$out" 2>/dev/null)
  rm -f "$out"
fi

# Tolerant OK detection: "OK", "OK.", "OK — all clear" etc. all pass. A
# verdict whose first line is OK-ish and which contains no violation
# bullets is a pass; only real findings block.
[ -z "$verdict" ] && exit 0
norm=$(printf '%s' "$verdict" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:][:punct:]]//g')
[ "$norm" = "ok" ] && exit 0
first=$(printf '%s\n' "$verdict" | sed -n '/[^[:space:]]/{p;q;}' | tr '[:upper:]' '[:lower:]')
case "$first" in
  ok*)
    printf '%s\n' "$verdict" | grep -qE '^[[:space:]]*[-*]' || exit 0
    ;;
esac

printf '%s' "$payload_hash" > "$ack_file" 2>/dev/null || true
{
  echo "lenore doc-lint (advisory, $judge_label): the doc files in this commit have judgment-rule issues —"
  printf '%s\n' "$verdict"
  echo "Fix them now (they are not yet committed, and you still have the context a future reader won't),"
  echo "then re-run the commit. If you judge the lint wrong, re-running the same commit unchanged proceeds."
} >&2
exit 2
