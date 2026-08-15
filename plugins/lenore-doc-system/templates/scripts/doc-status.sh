#!/usr/bin/env bash
# usage: scripts/doc-status.sh
# what it does: prints one status line summarizing doc-system drift
# (last journal age, commit gap, stale branch-task files, bug count,
# Someday count, stale/dangling desk links, semantic-index staleness).
# Silent (exit 0) when not in a repo with docs/. Fast — meant to run on
# every session start.
set -uo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -d docs ] || exit 0

now=$(date +%s)
day=86400

# --- last journal entry age + commits since ---------------------------
journal_part=""
if [ -d docs/journal ] && [ -n "$(ls -A docs/journal 2>/dev/null)" ]; then
  newest_sha=$(git log -1 --diff-filter=A --format=%H -- 'docs/journal/*' 2>/dev/null)
  if [ -n "${newest_sha:-}" ]; then
    newest_commit=$(git log -1 --format=%ct "$newest_sha" 2>/dev/null)
    age_days=$(( (now - newest_commit) / day ))
    commits_since=$(git rev-list --count --first-parent "${newest_sha}..HEAD" 2>/dev/null | tr -d ' ')
    journal_part="last journal ${age_days}d ago (${commits_since} commits)"
  fi
fi
[ -z "$journal_part" ] && journal_part="no journal entries yet"

# --- stale branch-task files (no commits on branch in 14 days, or the
# branch no longer exists at all — slug convention: branch name with every
# "/" replaced by "-") ---------------------------------------------------
stale_branch_tasks=0
stale_task_files=""
if [ -d docs/tasks ]; then
  # Build slug -> branch-name map for all local branches once.
  branch_slugs=$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)
  for f in docs/tasks/branch-*.md; do
    [ -e "$f" ] || continue
    slug=$(basename "$f" .md | sed 's/^branch-//')
    match=""
    while IFS= read -r b; do
      [ -z "$b" ] && continue
      b_slug=$(printf '%s' "$b" | tr '/' '-')
      if [ "$b_slug" = "$slug" ]; then
        match="$b"
        break
      fi
    done <<< "$branch_slugs"
    if [ -n "$match" ]; then
      last_commit=$(git log -1 --format=%ct "$match" 2>/dev/null || echo 0)
      age_days=$(( (now - last_commit) / day ))
      [ "$age_days" -ge 14 ] && stale_branch_tasks=$((stale_branch_tasks + 1))
    else
      # branch no longer exists locally — the strongest staleness signal
      stale_branch_tasks=$((stale_branch_tasks + 1))
      stale_task_files="${stale_task_files}stale-task:${f} "
    fi
  done
fi

# --- bug count ----------------------------------------------------------
bug_count=0
if [ -d docs/bugs ]; then
  bug_count=$(ls docs/bugs/*.md 2>/dev/null | wc -l | tr -d ' ')
fi

# --- Someday count --------------------------------------------------------
someday_count=0
if [ -f docs/tasks/project.md ]; then
  someday_count=$(awk '/^#+ *Someday/{f=1;next} /^#+ /{f=0} f && /^[-*] /{c++} END{print c+0}' docs/tasks/project.md)
fi

# --- stale / dangling desk links -----------------------------------------
stale_desk=0
dangling_desk=0
if [ -d docs/desk ]; then
  for l in docs/desk/*; do
    [ -L "$l" ] || continue
    if [ ! -e "$l" ]; then
      dangling_desk=$((dangling_desk + 1))
      continue
    fi
    mtime=$(stat -f %m "$l" 2>/dev/null || stat -c %Y -- "$l" 2>/dev/null || echo "$now")
    age_days=$(( (now - mtime) / day ))
    [ "$age_days" -ge 14 ] && stale_desk=$((stale_desk + 1))
  done
fi

desk_part="desk: ${stale_desk} stale, ${dangling_desk} dangling"

# --- semantic-search index staleness (docs-search.py) --------------------
docs_index_part=""
if [ -f .docs-embeddings/meta.json ]; then
  stale_docs=$(find docs -type f \( -name "*.md" -o -name "*.html" \) -newer .docs-embeddings/meta.json 2>/dev/null | grep -v '^docs/desk/' | wc -l | tr -d ' ')
  stale_exp=0
  [ -d experiments ] && stale_exp=$(find experiments -maxdepth 3 -type f \( -name "README.md" -o -path "*/runs/*.md" \) -newer .docs-embeddings/meta.json 2>/dev/null | wc -l | tr -d ' ')
  stale_total=$((stale_docs + stale_exp))
  # docs-search.py auto-refreshes incrementally on every search, so this
  # isn't "stale" in the sense of giving wrong answers — just files that
  # haven't been embedded yet; the next search embeds them automatically.
  [ "$stale_total" -gt 0 ] && docs_index_part=" · docs-index: ${stale_total} pending (embeds on next search)"
else
  # Bounded scan: stop counting past 21 — we only need to know ">20", not
  # the exact count, so don't walk the whole tree on a huge repo.
  doc_file_count=$(find docs -type f \( -name "*.md" -o -name "*.html" \) 2>/dev/null | grep -v '^docs/desk/' | head -21 | wc -l | tr -d ' ')
  if [ "$doc_file_count" -gt 20 ]; then
    total_doc_files=21
  else
    exp_file_count=0
    [ -d experiments ] && exp_file_count=$(find experiments -maxdepth 2 -type f -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
    total_doc_files=$((doc_file_count + exp_file_count))
  fi
  if [ "$total_doc_files" -gt 20 ]; then
    docs_index_part=" · docs-index: none (semantic search off — see semantic-search-setup)"
  fi
fi

stale_task_part=""
if [ -n "$stale_task_files" ]; then
  stale_task_part=" · $(printf '%s' "$stale_task_files" | sed 's/ *$//')"
fi

echo "docs: ${journal_part} · stale branch-tasks: ${stale_branch_tasks} · bugs: ${bug_count} · someday: ${someday_count} · ${desk_part}${docs_index_part}${stale_task_part}"
