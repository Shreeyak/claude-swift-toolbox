#!/usr/bin/env bash
# Lenore doc system — advisory drift lint (PostToolUse hook).
# After a Write/Edit to a docs/ file, a cheap model checks the file against
# the JUDGMENT rules the deterministic hooks can't check (does line 1 actually
# summarize? is a task entry self-contained? one topic per note? repro in a
# bug file?) and, only if something's off, injects a short reminder into the
# session as additional context. Advisory only — never blocks anything; the
# file is uncommitted at this point, so the reminder arrives while the writing
# agent still has the context to fix it. Fail-open on any error.
#
# Disable with LENORE_NO_LINT=1. Requires the `claude` CLI; silently no-ops
# without it.
set -uo pipefail

[ "${LENORE_NO_LINT:-0}" = "1" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

input=$(cat)

file=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null) || exit 0
[ -n "$file" ] || exit 0

root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/docs/CLAUDE.md" ] || exit 0   # only lint repos running this doc system

case "$file" in
  */docs/journal/*.md|*/docs/notes/*.md|*/docs/bugs/*.md|*/docs/tasks/*.md) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

rel=${file#"$root"/}

verdict=$(claude -p --model claude-haiku-4-5-20251001 --max-turns 1 <<EOF 2>/dev/null
You are a documentation linter. Check ONE file against the rules for its class.
Shape rules (length caps, line-1-not-a-heading) are enforced elsewhere — check
only the judgment rules below. Reply with exactly "OK" if the file is fine or
you are unsure; otherwise reply with at most 3 short bullet lines, each naming
the rule broken and the offending text. Flag only confident violations.

Rules by path:
- docs/journal/: plain prose telling the arc of what happened (no task lists,
  no implementation detail dumps); line 1 states the event in one sentence.
- docs/notes/: one topic per note; line 1 is a genuine one-sentence summary of
  the body (not a title fragment); no status markers like "OBSOLETE"/"CURRENT"
  (a correcting note says "Revises <file>" instead).
- docs/bugs/: must contain enough to act on later — a repro or trigger,
  expected vs actual; not just a restatement of the title.
- docs/tasks/: every entry readable by someone with NONE of the writing
  session's context — no unexplained shorthand ("the fix", "the sweep", bare
  jargon); files/commits/parameters named; entries are 1 title line + <=5
  context lines or a "— details: notes/..." pointer.

File: $rel
Content:
$(cat "$file")
EOF
) || exit 0

case "$verdict" in
  OK|ok|Ok|"") exit 0 ;;
esac

printf '%s' "$verdict" | python3 -c '
import json, sys
v = sys.stdin.read().strip()
if not v or v.upper() == "OK":
    sys.exit(0)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "lenore doc-lint (advisory, haiku) on the file just written — fix now while you still have the context (file is uncommitted):\n" + v,
    }
}))
' 2>/dev/null
exit 0
