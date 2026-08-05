#!/usr/bin/env bash
# UserPromptSubmit: when the user's prompt is an explicit code-navigation
# question AND a semantic tool is configured here, emit ONE line before the
# model picks a tool.
#
# This is the only pre-decision moment a hook gets that can actually carry a
# message: PreToolUse fires earlier but has no `additionalContext` channel, so
# the companion grep nudge is PostToolUse and necessarily arrives after the
# model has already chosen grep. This one fires before it chooses.
#
# Regex-only, no filesystem walk beyond a few stat calls, fail-open, silent
# otherwise. Pure bash, no interpreter shell-outs.

set +e

# Read the hook payload (JSON on stdin) and pull out the prompt without a JSON
# parser: we only need a lowercase haystack for a regex match, so a crude
# extraction is sufficient and cannot fail closed.
payload=$(cat 2>/dev/null)
[ -z "$payload" ] && exit 0

haystack=$(printf '%s' "$payload" | tr 'A-Z' 'a-z' | tr -d '\n')

case "$haystack" in
  *"who calls"*|*"callers of"*|*"references to"*|*"all references"*|\
  *"find implementations"*|*"implementations of"*|*"who implements"*|\
  *"rename the symbol"*|*"rename this symbol"*|*"rename "*"across the"*|\
  *"where is "*" defined"*|*"where is "*" used"*|*"usages of"*|\
  *"find all usages"*|*"call sites"*|*"call hierarchy"*) ;;
  *) exit 0 ;;
esac

# Only speak when a semantic tool actually exists here -- otherwise the line is
# advice the session cannot act on.
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$cwd" 2>/dev/null || exit 0

have() { command -v "$1" >/dev/null 2>&1; }
semantic=""
[ -f .serena/project.yml ] && have serena && semantic="serena"
for b in typescript-language-server basedpyright-langserver clangd sourcekit-lsp; do
  have "$b" && semantic="${semantic:+$semantic/}LSP" && break
done
[ -z "$semantic" ] && exit 0

msg="Navigation question. A semantic tool is configured here ($semantic) -- use it for references/definitions rather than grep, and see the code-intel routing skill for the mechanism-class caveats."

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/\\r}
  s=${s//$'\n'/\\n}
  printf '"%s"' "$s"
}

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}\n' \
  "$(json_escape "$msg")"
exit 0
