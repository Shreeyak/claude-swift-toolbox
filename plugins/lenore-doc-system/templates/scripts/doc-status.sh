#!/usr/bin/env bash
# usage: scripts/doc-status.sh
# what it does: prints one status line summarizing doc-system drift
# (last journal age, commit gap, stale branch-task files, bug count,
# Someday count, stale/dangling desk links, semantic-index staleness,
# unreflected experiment runs, untriaged run outputs, orphan store dirs).
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
  [ -d experiments ] && stale_exp=$(find experiments -maxdepth 3 -type f \( -name "README.md" -o -path "*/notebook/*.md" -o -path "*/runs/*.md" \) -newer .docs-embeddings/meta.json 2>/dev/null | wc -l | tr -d ' ')
  stale_spec=0
  [ -d openspec ] && stale_spec=$(find openspec -type f -name "*.md" ! -name "tasks.md" -newer .docs-embeddings/meta.json 2>/dev/null | wc -l | tr -d ' ')
  stale_total=$((stale_docs + stale_exp + stale_spec))
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

# --- dangling pointers (task "— details:" -> notes, note "Revises" -> note) --
dangling_ptr_part=""
dang=""
if [ -d docs/tasks ]; then
  for tf in docs/tasks/*.md; do
    [ -e "$tf" ] || continue
    for ref in $(grep -oE '(docs/)?notes/[A-Za-z0-9._-]+\.md' "$tf" 2>/dev/null | sort -u); do
      rel="${ref#docs/}"
      [ -f "docs/$rel" ] || dang="${dang}${tf}->${rel} "
    done
  done
fi
if [ -d docs/notes ]; then
  for ref in $(grep -hoE '^Revises (docs/)?notes/[A-Za-z0-9._-]+\.md' docs/notes/*.md 2>/dev/null | awk '{print $2}' | sort -u); do
    rel="${ref#docs/}"
    [ -f "docs/$rel" ] || dang="${dang}revises->${rel} "
  done
fi
if [ -n "$dang" ]; then
  dang_n=$(printf '%s' "$dang" | wc -w | tr -d ' ')
  dang_first=$(printf '%s' "$dang" | awk '{print $1}')
  dangling_ptr_part=" · dangling-pointers: ${dang_n} (${dang_first})"
fi

# --- unreflected experiment runs (>=2 runs committed after README's last commit) --
unreflected_part=""
unref=""
if [ -d experiments ]; then
  for er in experiments/*/README.md; do
    [ -e "$er" ] || continue
    exp=${er%/README.md}
    readme_ct=$(git log -1 --format=%ct -- "$er" 2>/dev/null)
    [ -n "$readme_ct" ] || continue
    newer=0
    for rf in "$exp"/notebook/*.md "$exp"/runs/*.md; do
      [ -e "$rf" ] || continue
      run_ct=$(git log -1 --format=%ct -- "$rf" 2>/dev/null)
      [ -n "$run_ct" ] || continue
      [ "$run_ct" -gt "$readme_ct" ] && newer=$((newer + 1))
    done
    [ "$newer" -ge 2 ] && unref="${unref}$(basename "$exp") "
  done
fi
if [ -n "$unref" ]; then
  unref_n=$(printf '%s' "$unref" | wc -w | tr -d ' ')
  unref_first=$(printf '%s' "$unref" | awk '{print $1}')
  unreflected_part=" · unreflected-runs: ${unref_n} exp (${unref_first})"
fi

# --- experiment store health (untriaged run outputs + orphaned store dirs) --
# Untriaged: out/<run>/ dirs newer than the experiment's .lenore-triaged
# marker (touched by /doc-cleanup's triage pass); all of them if no marker.
# Orphan: a data/experiments/<name> with no experiments/<name> in the repo.
store_part=""
if [ -d data/experiments ]; then
  untriaged=0
  orphans=0
  orphan_first=""
  for sd in data/experiments/*/; do
    [ -d "$sd" ] || continue
    name=$(basename "$sd")
    if [ ! -d "experiments/$name" ]; then
      orphans=$((orphans + 1))
      [ -z "$orphan_first" ] && orphan_first="$name"
      continue
    fi
    if [ -d "$sd/out" ]; then
      # ! -name '.*' skips the CLI's hidden .runNNN.lock reservation dirs
      if [ -f "$sd/.lenore-triaged" ]; then
        n=$(find "$sd/out" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -newer "$sd/.lenore-triaged" 2>/dev/null | wc -l | tr -d ' ')
      else
        n=$(find "$sd/out" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
      fi
      untriaged=$((untriaged + n))
    fi
  done
  [ "$untriaged" -gt 0 ] && store_part="${store_part} · untriaged-runs: ${untriaged}"
  [ "$orphans" -gt 0 ] && store_part="${store_part} · orphan-store-dirs: ${orphans} (${orphan_first})"
fi

stale_task_part=""
if [ -n "$stale_task_files" ]; then
  stale_task_part=" · $(printf '%s' "$stale_task_files" | sed 's/ *$//')"
fi

echo "docs: ${journal_part} · stale branch-tasks: ${stale_branch_tasks} · bugs: ${bug_count} · someday: ${someday_count} · ${desk_part}${docs_index_part}${dangling_ptr_part}${unreflected_part}${store_part}${stale_task_part}"
