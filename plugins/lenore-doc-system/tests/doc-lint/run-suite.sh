#!/usr/bin/env bash
# usage: tests/doc-lint/run-suite.sh [scratch-dir]
# what it does: runs the doc-lint judgment suite (cases/) against the live
# doc-lint.sh + doc-lint-judge agent prompt in a throwaway git repo and
# prints a PASS/BLOCK-vs-expected matrix. ~17 Haiku calls; needs `claude`.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
plugin_root=$(cd "$here/../.." && pwd)
script="$plugin_root/templates/scripts/doc-lint.sh"
scratch="${1:-$(mktemp -d)}/doclint-suite"

rm -rf "$scratch"; mkdir -p "$scratch"; cd "$scratch"
git init -q -b main
mkdir -p docs/{journal,notes,bugs,tasks}
echo placeholder > docs/CLAUDE.md
git add -A && git commit -qm init

hookjson='{"tool_name":"Bash","tool_input":{"command":"git add -A && git commit -m t"}}'
fails=0
for case_file in "$here"/cases/*.md; do
  base=$(basename "$case_file")
  case "$base" in
    J*) dir=journal ;;
    N*) dir=notes ;;
    B*) dir=bugs ;;
    T*) dir=tasks ;;
  esac
  case "$base" in
    *good*|*borderline*) expected=PASS ;;
    *) expected=BLOCK ;;
  esac
  git checkout -q -- docs 2>/dev/null; git clean -fdq docs 2>/dev/null
  rm -f .git/lenore-lint-ack
  mkdir -p "docs/$dir"
  cp "$case_file" "docs/$dir/$base"
  if printf '%s' "$hookjson" | bash "$script" "$plugin_root" >/dev/null 2>&1; then
    actual=PASS
  else
    actual=BLOCK
  fi
  mark=ok; [ "$actual" != "$expected" ] && { mark="** MISMATCH **"; fails=$((fails+1)); }
  printf '%-40s expected=%-5s actual=%-5s %s\n' "$base" "$expected" "$actual" "$mark"
done
echo "---"
[ "$fails" -eq 0 ] && echo "suite clean" || echo "$fails mismatch(es)"
exit "$fails"
