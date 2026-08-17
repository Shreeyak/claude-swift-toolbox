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
mkdir -p docs/{journal,notes,bugs,tasks} experiments/masked-ncc/runs
echo placeholder > docs/CLAUDE.md
cat > experiments/masked-ncc/README.md <<'FIXTURE'
---
status: concluded
verdict: Masked NCC beats the unmasked baseline (2.1px vs 5.8px mean error) and is the production default at window 64.
concluded: 2026-08-10
---
# masked-ncc

## Question
Does masking the correlation window to the segmented target improve alignment accuracy?

## What worked
Masked NCC at window 64 — 2.1px mean error vs 5.8px unmasked baseline on data/clips.

## What didn't
Feathered mask edges (no measurable gain over hard mask).

## Lifted into production
src/align.py --mask, window 64.

## Not pursued
Learned masks.
FIXTURE
git add -A && git commit -qm init

hookjson='{"tool_name":"Bash","tool_input":{"command":"git add -A && git commit -m t"}}'
fails=0
for case_file in "$here"/cases/*.md; do
  base=$(basename "$case_file")
  case "$base" in
    J*) dest=docs/journal ;;
    N*) dest=docs/notes ;;
    B*) dest=docs/bugs ;;
    T*) dest=docs/tasks ;;
    R*) dest=experiments/masked-ncc/runs ;;
  esac
  case "$base" in
    *good*|*borderline*) expected=PASS ;;
    *) expected=BLOCK ;;
  esac
  git checkout -q -- docs experiments 2>/dev/null; git clean -fdq docs experiments 2>/dev/null
  rm -f .git/lenore-lint-ack
  mkdir -p "$dest"
  cp "$case_file" "$dest/$base"
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
