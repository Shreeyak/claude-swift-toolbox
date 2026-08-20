#!/usr/bin/env bash
# usage: scripts/truth-candidates.sh <merge-base> <head>
# what it does: deterministic candidate collector for the landing-time
# reverse-drift check (see references/reverse-drift-check.md in the
# doc-system skill). Scans the CURRENT-TRUTH doc set for mentions of
# code the branch changed and prints a manifest of "read this doc line
# against that change" candidates for the code-doc-sync-reviewer agent.
# A candidate is a read-prompt, never a finding — this script does not
# judge prose and never edits anything.
#
# Tiers (in the manifest):
#   tier1  changed path quoted in a truth doc — full repo-relative
#          path, or bare basename when the name is distinctive
#          (identifier-shaped or >=8-char stem; main.py never matches)
#          (deletes/renames are the prime candidates — a doc naming a
#          path that no longer exists is exactly what needs review)
#   tier2  backticked identifier-shaped token in a truth doc that ALSO
#          appears in the branch's diff hunks (`Config` alone never
#          qualifies; `QualGateProd()`/`quality_gate.mm` do)
# tier3 (semantic/embedding hits) is the reviewer's job via
# docs-search.py — kept out of this script so it stays deterministic.
#
# Churn damping: a target mentioned by more than CHURN_CAP distinct
# truth docs (project.yml-style infra) collapses to one summary line.
# Cap: CAND_CAP candidates; overflow is LISTED BY NAME, never silently
# dropped, so /doc-health can inherit it.
set -uo pipefail

CAND_CAP=50
CHURN_CAP=8

base="${1:-}"; head="${2:-HEAD}"
if [ -z "$base" ]; then
  echo "usage: truth-candidates.sh <merge-base> [head]" >&2
  exit 1
fi
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 1
cd "$root" || exit 1

# --- the current-truth set (single definition; reviewer + docs cite it) ---
truth_docs() {
  for f in docs/system.md docs/caveats.md docs/playbook.md \
           docs/system/*.md docs/caveats/*.md docs/playbook/*.md \
           openspec/specs/*.md openspec/specs/*/*.md \
           experiments/*/README.md; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
}
# NOT in the set: journal/notes/tasks/bugs/proposals (dated or disposable,
# not current truth) and openspec/changes/ (plans, reconciled separately).

tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT

# --- changed paths (both sides of renames; status letter kept) -----------
git diff --name-status -M "$base" "$head" 2>/dev/null | awk '
  /^R/ { print $1 "\t" $2; print $1 "\t" $3; next }
  NF >= 2 { print $1 "\t" $2 }
' > "$tmpdir/changed" || true
[ -s "$tmpdir/changed" ] || { echo "# truth-candidates ${base}..${head}: no changed files"; exit 0; }

# Diff hunk text (added/removed lines only) for tier-2 token confirmation.
git diff -M --unified=0 "$base" "$head" 2>/dev/null \
  | grep -E '^[+-][^+-]' > "$tmpdir/hunks" || true

truth_docs > "$tmpdir/docs"
[ -s "$tmpdir/docs" ] || { echo "# truth-candidates ${base}..${head}: no current-truth docs in this repo"; exit 0; }

# --- tier 1: exact changed paths quoted in truth docs --------------------
# rows: doc<TAB>line<TAB>tier<TAB>target<TAB>status<TAB>excerpt
: > "$tmpdir/rows"
sort -u -t"$(printf '\t')" -k2 "$tmpdir/changed" | while IFS=$(printf '\t') read -r st p; do
  [ -n "$p" ] || continue
  st="${st%%[0-9]*}"   # R100 -> R, C75 -> C
  case "$p" in docs/*|openspec/*|experiments/*/README.md) continue ;; esac  # doc-side churn isn't a code target
  # Basename lexical channel: docs usually cite files by basename, not
  # full path (measured on mac-stitch: this catches every literal-mention
  # case a BM25 index would, with no index). Distinctive names only —
  # identifier-shaped or >=8-char stems; main.py/index.ts stay out.
  bn=$(basename "$p")
  stem="${bn%.*}"
  if [ "$bn" = "$p" ] || ! printf '%s' "$stem" | grep -qE '(_[a-z0-9]|-[a-z0-9]|[a-z][A-Z]|^.{8,}$)'; then
    bn=""
  fi
  while IFS= read -r doc; do
    grep -nF -- "$p" "$doc" 2>/dev/null | head -3 | while IFS=: read -r ln rest; do
      ex=$(printf '%s' "$rest" | sed 's/^[[:space:]]*//' | cut -c1-110)
      printf '%s\t%s\ttier1\t%s\t%s\t%s\n' "$doc" "$ln" "$p" "$st" "$ex"
    done
    if [ -n "$bn" ] && ! grep -qF -- "$p" "$doc" 2>/dev/null; then
      grep -nF -- "$bn" "$doc" 2>/dev/null | head -3 | while IFS=: read -r ln rest; do
        ex=$(printf '%s' "$rest" | sed 's/^[[:space:]]*//' | cut -c1-110)
        printf '%s\t%s\ttier1\t%s\t%s\t%s\n' "$doc" "$ln" "$p" "$st" "$ex"
      done
    fi
  done < "$tmpdir/docs"
done >> "$tmpdir/rows"

# --- tier 2: backticked identifier-shaped tokens also present in hunks ---
# Identifier-shaped: snake_case, CamelCase, call() form, or extension-
# bearing filename. Plain words and short tokens never qualify.
while IFS= read -r doc; do
  grep -noE '`[^` ]{4,80}`' "$doc" 2>/dev/null | while IFS=: read -r ln tok; do
    tok=${tok#\`}; tok=${tok%\`}
    printf '%s' "$tok" | grep -qE '^[A-Za-z0-9_./()-]+$' || continue
    if ! printf '%s' "$tok" | grep -qE '(_[a-z0-9]|[a-z][A-Z]|\(\)$|\.[A-Za-z0-9]{1,8}$)'; then
      continue  # not identifier-shaped
    fi
    bare=${tok%()}
    # must also appear in the branch's diff hunks (precision filter)
    grep -qF -- "$bare" "$tmpdir/hunks" || continue
    # tier-1 already covers exact changed paths (match tier1 rows only —
    # a token must still surface once per DOC that mentions it)
    grep -qF -- "$(printf '\t')tier1$(printf '\t')${tok}$(printf '\t')" "$tmpdir/rows" && continue
    line=$(sed -n "${ln}p" "$doc" | sed 's/^[[:space:]]*//' | cut -c1-110)
    printf '%s\t%s\ttier2\t%s\tM\t%s\n' "$doc" "$ln" "$tok" "$line"
  done
done < "$tmpdir/docs" >> "$tmpdir/rows"

[ -s "$tmpdir/rows" ] || { echo "# truth-candidates ${base}..${head}: no candidates (0 truth-doc mentions of changed code)"; exit 0; }

# --- dedupe by (doc, target), stable order: tier1 first, then doc order --
sort -t"$(printf '\t')" -k3,3 -k1,1 -k2,2n "$tmpdir/rows" \
  | awk -F'\t' '!seen[$1 FS $4]++' > "$tmpdir/deduped"

# --- churn damping: a target in > CHURN_CAP distinct docs -> one line ----
awk -F'\t' '{ if (!d[$4 FS $1]++) n[$4]++ } END { for (t in n) if (n[t] > '"$CHURN_CAP"') print t }' \
  "$tmpdir/deduped" > "$tmpdir/churny"
if [ -s "$tmpdir/churny" ]; then
  awk -F'\t' 'NR==FNR{c[$0]=1;next} !($4 in c)' "$tmpdir/churny" "$tmpdir/deduped" > "$tmpdir/kept"
else
  cp "$tmpdir/deduped" "$tmpdir/kept"
fi

total=$(wc -l < "$tmpdir/kept" | tr -d ' ')
echo "# truth-candidates ${base}..${head} — $total candidate(s), cap ${CAND_CAP}"
echo "# doc:line | tier | target | A/M/D/R | excerpt"
head -"$CAND_CAP" "$tmpdir/kept" | awk -F'\t' '{ printf "%s:%s | %s | %s | %s | %s\n", $1, $2, $3, $4, $5, $6 }'

if [ -s "$tmpdir/churny" ]; then
  echo "# churn-damped (target in >${CHURN_CAP} truth docs — verify once, not per doc):"
  while IFS= read -r t; do
    n=$(awk -F'\t' -v t="$t" '$4==t { if (!d[$1]++) n++ } END { print n+0 }' "$tmpdir/deduped")
    echo "#   $t (mentioned in $n truth docs)"
  done < "$tmpdir/churny"
fi

if [ "$total" -gt "$CAND_CAP" ]; then
  echo "# overflow ($((total - CAND_CAP)) beyond the cap — named for /doc-health, not reviewed at this landing):"
  tail -n +"$((CAND_CAP + 1))" "$tmpdir/kept" | awk -F'\t' '{ printf "#   %s | %s\n", $1, $3 }'
fi
