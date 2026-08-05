#!/usr/bin/env bash
# SessionStart: emit at most two lines of *dynamic* code-intelligence status.
#
# Deliberately silent when there is nothing actionable. SessionStart fires on
# begin AND resume, so anything static here would be re-emitted every resume and
# would train the model to skip it. The routing knowledge lives in the skill;
# this hook only reports facts that change per repo and per machine.
#
# Pure bash, no network, no builds, no interpreter shell-outs, fail-open.

set +e

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
status_script="$root/scripts/code-intel-status.sh"
[ -x "$status_script" ] || [ -f "$status_script" ] || exit 0

msg=$(bash "$status_script" 2>/dev/null)
[ -z "$msg" ] && exit 0

# Minimal JSON string escaper: backslash, quote, then the control characters a
# status line can plausibly contain. No python3/jq -- a missing interpreter must
# not turn a status line into a hook error.
json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/\\r}
  s=${s//$'\n'/\\n}
  printf '"%s"' "$s"
}

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' \
  "$(json_escape "$msg")"
exit 0
