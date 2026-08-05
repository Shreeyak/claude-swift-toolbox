#!/usr/bin/env bash
# Shared status renderer for the code-intel plugin.
#
# Used by hooks/session-start-code-intel.sh (compact, <=2 lines) and by
# /code-intel:doctor (verbose, with fixes). Pure bash, no network, no builds,
# no interpreter shell-outs. Any error exits 0 with whatever was rendered.
#
# States, per tool:
#   off   not configured here
#   cfg   configured, unverified (config parses, binary present)
#   live  a cheap local artifact proves it has actually run (index/graph file present)
#   !     configured but unsatisfiable (binary missing, artifact stale/absent)
#
# "live" is a cheap proxy, not proof of correctness. A language server can be on
# PATH, start, and still answer wrongly (clangd with no compile database is the
# standard case). Only the doctor's known-answer semantic probe settles that, and
# that probe cannot run from bash -- see doctor.md.
#
# Usage: code-intel-status.sh [--verbose]
# Env:   CLAUDE_PROJECT_DIR (falls back to PWD)

set +e
VERBOSE=0
[ "$1" = "--verbose" ] && VERBOSE=1

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$cwd" 2>/dev/null || exit 0

# ---------------------------------------------------------------- detection --
# Profile markers. Works with or without git (a plain directory is fine).
profiles=""
add_profile() { case " $profiles " in *" $1 "*) ;; *) profiles="$profiles $1" ;; esac; }

[ -f tsconfig.json ] || [ -f package.json ] && add_profile ts
[ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ] && add_profile py
[ -f CMakeLists.txt ] || [ -f compile_commands.json ] && add_profile cpp
[ -f Package.swift ] && add_profile swift
ls ./*.xcworkspace >/dev/null 2>&1 && add_profile swift
ls ./*.xcodeproj >/dev/null 2>&1 && add_profile swift
[ -f package.xml ] && add_profile cpp
profiles="${profiles# }"

have() { command -v "$1" >/dev/null 2>&1; }

# stale_days FILE DAYS -> 0 if file exists and is newer than DAYS
fresh_file() {
  [ -f "$1" ] || return 1
  [ -z "$(find "$1" -mtime "+$2" -print 2>/dev/null)" ]
}

# ------------------------------------------------------------------ serena ---
serena_state="off"; serena_fix=""
if [ -f .serena/project.yml ]; then
  if have serena; then
    if [ -d .serena/cache ]; then serena_state="live"; else serena_state="cfg"; fi
  else
    serena_state="!"; serena_fix="serena configured but not on PATH"
  fi
fi

# --------------------------------------------------------------- lsp servers -
# Reported per detected profile: is the server binary the code-intel-lsp plugin
# declares for this profile actually present?
lsp_missing=""
lsp_present=""
check_lsp() {  # check_lsp <profile> <binary>
  case " $profiles " in *" $1 "*) ;; *) return ;; esac
  if have "$2"; then lsp_present="$lsp_present $2"; else lsp_missing="$lsp_missing $2"; fi
}
check_lsp ts    typescript-language-server
check_lsp py    basedpyright-langserver
check_lsp cpp   clangd
check_lsp swift sourcekit-lsp
lsp_missing="${lsp_missing# }"; lsp_present="${lsp_present# }"

# ------------------------------------------------------------------ graphs ---
crg_state="off"; graphify_state="off"
if [ -d .code-review-graph ]; then
  if have code-review-graph; then
    if [ -f .code-review-graph/graph.db ]; then crg_state="live"; else crg_state="cfg"; fi
  else crg_state="!"; fi
fi
if [ -d graphify-out ]; then
  if have graphify || have graphify-mcp; then
    if fresh_file graphify-out/graph.json 30; then graphify_state="live"
    elif [ -f graphify-out/graph.json ]; then graphify_state="cfg"
    else graphify_state="!"; fi
  else graphify_state="!"; fi
fi

# ------------------------------------------------- declared-but-unsatisfiable -
# Absorbed from a standalone session-start hook: a project that *declares* a
# code-intelligence MCP server it cannot satisfy is the highest-value warning,
# because the failure is silent -- the server just never appears in the toolset.
declared_problems=""
add_problem() { declared_problems="${declared_problems}${declared_problems:+$'\n'}$1"; }
if [ -f .mcp.json ]; then
  if grep -q '"uvx"' .mcp.json 2>/dev/null; then
    add_problem ".mcp.json launches a server via uvx -> ephemeral-env rebuild stall; point it at the installed binary"
  fi
  for bin in serena code-review-graph graphify graphify-mcp; do
    if grep -q "\"$bin\"" .mcp.json 2>/dev/null && ! have "$bin"; then
      add_problem ".mcp.json needs '$bin' but it is not on PATH"
    fi
  done
  gpath=$(grep -o '/[^"]*graph\.json' .mcp.json 2>/dev/null | head -1)
  if [ -n "$gpath" ] && [ ! -f "$gpath" ]; then
    add_problem "graphify graph file referenced by .mcp.json does not exist"
  fi
fi

# ------------------------------------------------------------------- render --
semantic_available=0
case "$serena_state" in cfg|live) semantic_available=1 ;; esac
[ -n "$lsp_present" ] && semantic_available=1

if [ "$VERBOSE" = "1" ]; then
  echo "code-intel status for: $cwd"
  echo "  profiles detected : ${profiles:-none}"
  echo "  manifest          : $([ -f .code-intel.json ] && echo '.code-intel.json present' || echo 'none (run /code-intel:setup)')"
  echo "  serena            : $serena_state${serena_fix:+  ($serena_fix)}"
  echo "  lsp binaries      : present[${lsp_present:-none}] missing[${lsp_missing:-none}]"
  echo "  code-review-graph : $crg_state"
  echo "  graphify          : $graphify_state"
  if [ -n "$declared_problems" ]; then
    echo "  declared but unsatisfiable:"
    printf '    - %s\n' "$declared_problems"
  fi
  echo "  semantic tool configured: $([ "$semantic_available" = 1 ] && echo yes || echo no)"
  exit 0
fi

# Compact form: at most two lines, dynamic facts only, silent when there is
# nothing actionable. No static routing sentence -- that duplicates the skill
# description, and repeating it every resume trains ignoring it.
line1=""
line2=""

if [ -n "$declared_problems" ]; then
  first=$(printf '%s' "$declared_problems" | head -1)
  n=$(printf '%s\n' "$declared_problems" | grep -c .)
  line1="code-intel: $first"
  [ "$n" -gt 1 ] && line1="$line1 (+$((n - 1)) more)"
  line2="Run /code-intel:doctor."
elif [ -n "$lsp_missing" ] && [ "$semantic_available" = 0 ]; then
  line1="code-intel: profile [${profiles}] detected, no semantic tool available (missing:${lsp_missing:+ $lsp_missing})."
  line2="Run /code-intel:setup for install one-liners."
elif [ -n "$lsp_missing" ]; then
  line1="code-intel: language server not installed for this profile:${lsp_missing:+ $lsp_missing}."
fi

[ -z "$line1" ] && exit 0
printf '%s\n' "$line1"
[ -n "$line2" ] && printf '%s\n' "$line2"
exit 0
