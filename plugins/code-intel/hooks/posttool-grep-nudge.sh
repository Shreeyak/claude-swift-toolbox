#!/usr/bin/env bash
# PostToolUse (Grep | Bash): when a text search looks like a *symbol* lookup and a
# semantic tool is configured here, attach one corrective line to the result.
#
# Honest scope: this is CORRECTIVE, not preventive -- the search has already run
# and its output arrives together with this note. The pre-decision lever is the
# UserPromptSubmit router; this one shapes the rest of the session.
#
# WHY PostToolUse AND NOT PreToolUse (verified against the hooks reference,
# 2026-08-05). PreToolUse is the earlier event, but it is the wrong one here on
# both halves of the contract:
#   - PreToolUse does NOT carry `additionalContext`. Its only output channels are
#     `permissionDecision` and `permissionDecisionReason`, so the message below
#     would be silently discarded.
#   - `permissionDecision: "allow"` does not mean "do not block" -- it BYPASSES
#     the permission system for that call. A nudge must never auto-approve the
#     tool it is commenting on.
# PostToolUse supports `additionalContext` and has no say over permissions at
# all, which is exactly the causal power this hook should have. Do not "improve"
# this by moving it earlier.
#
# Non-blocking by design. grep has many legitimate lanes (constants, strings,
# prose, completeness cross-checks); denying it would teach workarounds and
# misfire constantly.
#
# The heuristic is deliberately loose and quiet -- a bare-identifier pattern of
# at least 4 characters, at most twice per session. It will miss symbol searches
# written as regexes; that is accepted, not a bug to parse away.
#
# Pure bash, no network, no interpreter shell-outs, fail-open.

set +e

payload=$(cat 2>/dev/null)
[ -z "$payload" ] && exit 0

# Crude field extraction -- no JSON parser available and none needed: every
# failure mode here ends in "no nudge", which is the safe direction.
field() {  # field <key> -> first string value for that key
  printf '%s' "$payload" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//'
}

tool=$(field tool_name)
sid=$(field session_id)

candidate=""
case "$tool" in
  Grep)
    candidate=$(field pattern)
    ;;
  Bash)
    cmd=$(field command)
    case "$cmd" in
      grep*|rg*|*"| grep"*|*"| rg"*) ;;
      *) exit 0 ;;
    esac
    # First non-flag argument after the search command.
    for w in $cmd; do
      case "$w" in
        grep|rg|egrep|ripgrep|\||*grep) continue ;;
        -*) continue ;;
        *) candidate="$w"; break ;;
      esac
    done
    candidate=${candidate#\'}; candidate=${candidate%\'}
    candidate=${candidate#\"}; candidate=${candidate%\"}
    ;;
  *) exit 0 ;;
esac

[ -z "$candidate" ] && exit 0

# Bare identifier, >= 4 chars, no regex metacharacters, no whitespace. Anchored
# regex, not a case glob -- a trailing `*` in a glob would happily match
# `foo.*bar` and nudge on every regex search.
[[ "$candidate" =~ ^[A-Za-z_][A-Za-z0-9_]{3,}$ ]] || exit 0

# ---------------------------------------------------------- semantic check --
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$cwd" 2>/dev/null || exit 0
have() { command -v "$1" >/dev/null 2>&1; }
semantic=""
[ -f .serena/project.yml ] && have serena && semantic="serena"
for b in typescript-language-server basedpyright-langserver clangd sourcekit-lsp; do
  have "$b" && semantic="${semantic:+$semantic or the }LSP" && break
done
[ -z "$semantic" ] && exit 0

# ------------------------------------------------------------- rate limit ---
# State lives in CLAUDE_PLUGIN_DATA (persists across plugin updates); falls back
# to a temp dir. Session id is sanitized before it reaches a path.
state_dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/code-intel}"
mkdir -p "$state_dir" 2>/dev/null || exit 0

safe_sid=$(printf '%s' "${sid:-nosession}" | tr -c 'A-Za-z0-9_-' '_' | cut -c1-64)
state_file="$state_dir/nudge-$safe_sid"

# Stale cleanup: sessions do not outlive a couple of days of wall clock.
find "$state_dir" -maxdepth 1 -name 'nudge-*' -mtime +2 -delete 2>/dev/null

count=0
[ -f "$state_file" ] && count=$(cat "$state_file" 2>/dev/null)
case "$count" in ''|*[!0-9]*) count=0 ;; esac
[ "$count" -ge 2 ] && exit 0

# Atomic write: temp file in the same directory, then rename. The budget is spent
# only on the path that reaches the printf below -- every earlier exit leaves it
# intact, so a session never loses a nudge to a message nobody saw.
tmp="$state_file.$$"
printf '%s\n' "$((count + 1))" > "$tmp" 2>/dev/null && mv -f "$tmp" "$state_file" 2>/dev/null
rm -f "$tmp" 2>/dev/null

# ----------------------------------------------------------------- output ---
msg="'$candidate' looks like a symbol, and that was a text search. Text search over-matches comments, strings, and unrelated same-named symbols, and it cannot tell a definition from a mention. $semantic is configured in this repo (configured -- not guaranteed working; /code-intel:doctor verifies) and answers references/definitions/implementations directly. If the result above feeds a rename, a delete, or any claim of completeness, re-ask it semantically. Text search remains the right tool for constants, string literals, and completeness cross-checks of a semantic answer."

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/\\r}
  s=${s//$'\n'/\\n}
  printf '"%s"' "$s"
}

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' \
  "$(json_escape "$msg")"
exit 0
