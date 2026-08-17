#!/usr/bin/env bash
# Lenore doc system — advisory drift lint (PreToolUse hook on Bash).
# Fires when the agent is about to run a `git commit`. Batches every new or
# modified docs/{journal,notes,bugs,tasks} .md file (worktree vs HEAD — the
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
# Requires the `claude` CLI; silently no-ops without it.
set -uo pipefail

[ "${LENORE_NO_LINT:-0}" = "1" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

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
files=$(git status --porcelain -- 'docs/journal/*.md' 'docs/notes/*.md' 'docs/bugs/*.md' 'docs/tasks/*.md' 2>/dev/null \
        | grep -E '^.?[AM?]' | sed 's/^...//' | sed 's/^"\(.*\)"$/\1/')
[ -n "$files" ] || exit 0

payload=""
count=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  [ "$count" -gt 8 ] && break   # bound the batch; a mega-commit lints its first 8
  payload="${payload}
=== FILE: $f ===
$(cat "$f")
"
done <<< "$files"
[ -n "$payload" ] || exit 0

# Warn-once: if this exact doc content was already flagged, let the retry
# through — a disputed judgment call costs one retry, never a standoff.
gitdir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
ack_file="$gitdir/lenore-lint-ack"
payload_hash=$(printf '%s' "$payload" | git hash-object --stdin 2>/dev/null || echo none)
if [ -f "$ack_file" ] && [ "$(cat "$ack_file" 2>/dev/null)" = "$payload_hash" ]; then
  rm -f "$ack_file"
  exit 0
fi

verdict=$(claude -p --model claude-haiku-4-5-20251001 --max-turns 1 <<EOF 2>/dev/null
You are a documentation linter run just before a commit. Check each file
against the rules for its path. Shape rules (length caps, line-1-not-a-heading)
are enforced elsewhere — check only the judgment rules below. Reply with
exactly "OK" if every file is fine or you are unsure; otherwise reply with at
most 3 short bullet lines total, each naming the file, the rule broken, and
the offending text. Flag only confident violations.

Rules by path:
- docs/journal/: plain prose telling the arc of what happened (no task lists,
  no implementation detail dumps); line 1 states the event in one sentence.
- docs/notes/: one topic per note; line 1 is a genuine one-sentence summary of
  the body (not a title fragment); no status markers like "OBSOLETE"/"CURRENT"
  (a correcting note says "Revises <file>" instead).
- docs/bugs/: must contain enough to act on later — a repro or trigger,
  expected vs actual; not just a restatement of the title.
- docs/tasks/: every entry readable by someone with NONE of the writing
  session's context. The test: could a competent developer act on it using
  only the repo? If yes, it is OK. Flag ONLY when a critical referent (a
  file, fix, dataset, experiment) cannot be located from what is written.
  Naming a parameter without explaining its theory is fine when the relevant
  file or commit is named. Entries are 1 title line + <=5 context lines or a
  "— details: notes/..." pointer — but short self-contained entries need no
  extra lines.

Calibration for docs/tasks/:
- VIOLATION: "re-run the sweep after the tau/mu fix (qwez1 clip may need tau
  lowered)" — which sweep? which fix? what is qwez1? Nothing is locatable.
- OK: "Re-run the placement sweep (scripts/sweep.py, all 3 scenarios) after
  the tau/mu threshold fix in Matcher.swift (commit abc123); the qwez1 test
  clip (data/clips/qwez1.mov) may need tau at 0.2." — every referent is
  locatable; do not flag entries like this for missing purpose/theory.
$payload
EOF
) || exit 0

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
  echo "lenore doc-lint (advisory, haiku): the doc files in this commit have judgment-rule issues —"
  printf '%s\n' "$verdict"
  echo "Fix them now (they are not yet committed, and you still have the context a future reader won't),"
  echo "then re-run the commit. If you judge the lint wrong, re-running the same commit unchanged proceeds."
} >&2
exit 2
