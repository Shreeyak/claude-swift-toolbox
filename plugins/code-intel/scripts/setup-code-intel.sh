#!/usr/bin/env bash
# code-intel setup: PROPOSE, then apply on request.
#
# Default run detects the stack, prints the full proposal plus a diff of every
# file it would change, and STOPS. `--write` applies it. Nothing is ever changed
# behind the reader's back, and no binary is ever installed -- missing tools are
# reported with an install one-liner for a human to run.
#
# The accepted proposal is recorded as `.code-intel.json` in the target repo.
# That manifest is the reviewable record and the idempotency key: a second
# `--write` with an unchanged proposal is a no-op.
#
# Usage:
#   setup-code-intel.sh [--write] [--dir <path>] [--force] [-h|--help]
#
# Exit codes: 0 ok (including "proposal printed, nothing written")
#             1 refused (malformed existing config -- never auto-repaired)
#             2 bad usage

set +e

WRITE=0
FORCE=0
TARGET="${CLAUDE_PROJECT_DIR:-$PWD}"
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

while [ $# -gt 0 ]; do
  case "$1" in
    --write) WRITE=1 ;;
    --force) FORCE=1 ;;
    --dir) shift; TARGET="$1" ;;
    -h|--help)
      sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

cd "$TARGET" 2>/dev/null || { echo "no such directory: $TARGET" >&2; exit 2; }
TARGET="$PWD"

have() { command -v "$1" >/dev/null 2>&1; }
say()  { printf '%s\n' "$*"; }
rule() { printf '%s\n' "----------------------------------------------------------------"; }

# ------------------------------------------------------------------ detect ---
profiles=""
add_profile() { case " $profiles " in *" $1 "*) ;; *) profiles="$profiles $1" ;; esac; }
evidence=""
note_evidence() { evidence="${evidence}${evidence:+$'\n'}  - $1"; }

if [ -f tsconfig.json ]; then add_profile ts; note_evidence "tsconfig.json -> typescript"
elif [ -f package.json ]; then add_profile ts; note_evidence "package.json -> javascript/typescript"; fi
if [ -f pyproject.toml ]; then add_profile py; note_evidence "pyproject.toml -> python"
elif [ -f setup.py ] || [ -f requirements.txt ]; then add_profile py; note_evidence "setup.py/requirements.txt -> python"; fi
if [ -f CMakeLists.txt ]; then add_profile cpp; note_evidence "CMakeLists.txt -> c/c++"; fi
if [ -f package.xml ]; then add_profile cpp; note_evidence "package.xml -> c/c++ (colcon-style workspace: per-package compile databases must be merged)"; fi
if [ -f compile_commands.json ]; then add_profile cpp; note_evidence "compile_commands.json -> c/c++ (compile database already present)"; fi
if [ -f Package.swift ]; then add_profile swift; note_evidence "Package.swift -> swift"; fi
if ls ./*.xcworkspace >/dev/null 2>&1; then add_profile swift; note_evidence "*.xcworkspace -> swift (needs a build-server bridge; see setup-swift.md)"; fi
if ls ./*.xcodeproj >/dev/null 2>&1 && ! ls ./*.xcworkspace >/dev/null 2>&1; then add_profile swift; note_evidence "*.xcodeproj -> swift"; fi
profiles="${profiles# }"

if [ -z "$profiles" ]; then
  say "code-intel: no known stack marker found in $TARGET."
  say "Covered markers: tsconfig.json, package.json, pyproject.toml, setup.py,"
  say "requirements.txt, CMakeLists.txt, package.xml, compile_commands.json,"
  say "Package.swift, *.xcworkspace, *.xcodeproj."
  say ""
  say "Other languages are still fully supported through serena and the routing"
  say "table -- see references/setup-generic.md. Nothing was written."
  exit 0
fi

# ----------------------------------------------------------- required tools --
lang_for() { case "$1" in ts) echo typescript ;; py) echo python ;; cpp) echo cpp ;; swift) echo swift ;; esac; }
server_for() {
  case "$1" in
    ts)    echo typescript-language-server ;;
    py)    echo basedpyright-langserver ;;
    cpp)   echo clangd ;;
    swift) echo sourcekit-lsp ;;
  esac
}
install_hint() {
  case "$1" in
    typescript-language-server) echo "npm i -g typescript-language-server typescript   # pin typescript@^5 in the workspace" ;;
    basedpyright-langserver)    echo "uv tool install basedpyright" ;;
    clangd)                     echo "brew install llvm   (macOS)  |  apt install clangd   (Debian/Ubuntu)" ;;
    sourcekit-lsp)              echo "ships with the Swift / Xcode toolchain: xcrun --find sourcekit-lsp" ;;
    serena)                     echo "uv tool install serena-agent   # Apple Silicon: add -p cpython-3.13-macos-aarch64-none" ;;
    code-review-graph)          echo "uv tool install code-review-graph   # Apple Silicon: add -p cpython-3.13-macos-aarch64-none" ;;
    graphify)                   echo "uv tool install 'graphifyy[mcp]'   # package is graphifyy, command is graphify" ;;
    ast-grep)                   echo "brew install ast-grep   |   npm i -g @ast-grep/cli   |   cargo install ast-grep" ;;
    semgrep)                    echo "uv tool install semgrep   # Apple Silicon: add -p cpython-3.13-macos-aarch64-none" ;;
    rg)                         echo "brew install ripgrep   |   apt install ripgrep" ;;
    vulture)                    echo "uv tool install vulture" ;;
    knip)                       echo "npm i -g knip" ;;
    *)                          echo "see references/tools-catalog.md" ;;
  esac
}

# One line per tool: what question it answers, so a MISSING line says what is
# lost rather than just naming a binary.
tool_role() {
  case "$1" in
    serena)            echo "symbol-exact navigation + symbol-level edits (semantic; ~50 languages)" ;;
    code-review-graph) echo "search by meaning, and diff review: semantic_search / detect-changes (name-match)" ;;
    graphify)          echo "the only tool here that indexes docs/ and prose alongside code (name-match)" ;;
    ast-grep)          echo "structural code patterns -- 'every await inside a loop' (textual, syntax-aware)" ;;
    semgrep)           echo "known security / correctness anti-patterns, some with dataflow (textual+)" ;;
    rg)                echo "constants, env vars, build flags, prose -- and completeness cross-checks" ;;
    vulture)           echo "[py] dead code / unused symbols" ;;
    knip)              echo "[ts] dead code / unused exports and dependencies" ;;
  esac
}

report_tool() {  # report_tool <bin> [optional-label]
  if have "$1"; then
    say "  [present] $1  --  $(tool_role "$1")"
  else
    say "  [MISSING] $1  --  $(tool_role "$1")"
    say "            install: $(install_hint "$1")"
  fi
}

serena_languages=""
missing_bins=""
present_bins=""
for p in $profiles; do
  serena_languages="$serena_languages${serena_languages:+, }$(lang_for "$p")"
  b=$(server_for "$p")
  if have "$b"; then present_bins="$present_bins $b"; else missing_bins="$missing_bins $b"; fi
done
missing_bins="${missing_bins# }"; present_bins="${present_bins# }"

# ------------------------------------------------------- planned file writes --
# Only files this manifest owns are ever touched. Existing content is preserved
# except for the keys named here.
plan_serena=0
plan_manifest=1
[ -f .serena/project.yml ] || plan_serena=1

# .mcp.json is PROPOSED (never merged). The old reason for refusing -- "MCP
# entries carry machine-specific absolute paths" -- is an argument for
# generating the file on the machine that will use it, which is this one:
# $TARGET is absolute and the binaries were just resolved with `have`. An
# existing .mcp.json is never rewritten; merging someone else's server list is
# exactly the silent destruction this script refuses elsewhere.
plan_mcp=0
mcp_servers=""
for b in serena code-review-graph graphify; do
  have "$b" && mcp_servers="$mcp_servers $b"
done
mcp_servers="${mcp_servers# }"
if [ -n "$mcp_servers" ] && [ ! -f .mcp.json ]; then plan_mcp=1; fi

# ------------------------------------------------------- JSON sanity check ----
# A malformed existing config is a REFUSAL, never an auto-repair: rewriting a
# file we could not parse is how a hand-tuned config gets silently destroyed.
json_ok() {  # json_ok <file> -> 0 valid, 1 invalid, 2 undecidable
  [ -f "$1" ] || return 0
  if have python3; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1 && return 0
    return 1
  fi
  # Fallback when no interpreter is available: a brace/bracket balance check.
  # Weaker than a parser -- it catches truncation and stray braces, not every
  # syntax error -- so it reports "undecidable" rather than "valid".
  local opens closes
  opens=$(tr -cd '{[' < "$1" | wc -c | tr -d ' ')
  closes=$(tr -cd '}]' < "$1" | wc -c | tr -d ' ')
  [ "$opens" = "$closes" ] || return 1
  return 2
}

refuse=""
for f in .mcp.json .code-intel.json; do
  json_ok "$f"; rc=$?
  [ "$rc" = "1" ] && refuse="${refuse}${refuse:+$'\n'}  - $f does not parse as JSON"
  [ "$rc" = "2" ] && say "code-intel: note - no python3 available, $f was only balance-checked, not parsed."
done
if [ -n "$refuse" ]; then
  say "code-intel: REFUSING to proceed. Existing configuration is malformed:"
  say "$refuse"
  say ""
  say "Fix it by hand (or move it aside) and re-run. This script never repairs a"
  say "file it could not parse -- doing so would silently discard hand-written config."
  exit 1
fi

# -------------------------------------------------------------- idempotency --
proposal_fingerprint="profiles=$profiles;serena_languages=$serena_languages"
existing_fingerprint=""
if [ -f .code-intel.json ]; then
  existing_fingerprint=$(grep -o '"fingerprint"[[:space:]]*:[[:space:]]*"[^"]*"' .code-intel.json 2>/dev/null \
    | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
fi
unchanged=0
[ -n "$existing_fingerprint" ] && [ "$existing_fingerprint" = "$proposal_fingerprint" ] && unchanged=1

# ------------------------------------------------------------------ render ---
rule
say "code-intel setup proposal"
say "  target : $TARGET"
say "  git    : $([ -d .git ] && echo 'repository' || echo 'plain directory (fine -- nothing here needs git)')"
rule
say "Detected stack: $profiles"
say "Evidence:"
printf '%s\n' "$evidence"
say ""
say "Language servers for this stack (provided by the code-intel-lsp plugin):"
for p in $profiles; do
  b=$(server_for "$p")
  if have "$b"; then say "  [present] $b"
  else
    say "  [MISSING] $b"
    say "            install: $(install_hint "$b")"
  fi
done
say ""
say "  Enable the servers with:  claude plugin enable code-intel-lsp"
say "  A server whose binary is absent is skipped; it does not claim its"
say "  extensions, so another plugin's server for the same extension still works."
say ""
if [ -n "$present_bins" ] || [ -n "$missing_bins" ]; then
  say "  CONFLICT CHECK (do this before enabling): if a single-language LSP plugin"
  say "  is already enabled for any of these extensions, the FIRST registered server"
  say "  wins and the other never starts. That is a conflict, not a benign overlap."
  say "  Run 'claude plugin list', and either disable the single-language plugins or"
  say "  do not enable code-intel-lsp in this project. Choose explicitly."
  say ""
fi

# The rest of the toolbelt. The routing table in SKILL.md sends real questions
# to every one of these, so setup reports on every one of them -- a tool that is
# never mentioned is a tool that never gets used.
say "Toolbelt (each answers a different class of question; see the routing table):"
report_tool serena
report_tool code-review-graph
report_tool graphify
report_tool ast-grep
report_tool semgrep
report_tool rg
for p in $profiles; do
  case "$p" in
    py) report_tool vulture ;;
    ts) report_tool knip ;;
  esac
done
say ""
say "  None of these is required. Each absence costs one lane of the routing"
say "  table, and the skill will say so rather than silently substituting grep."
say ""

if have graphify && [ ! -f graphify-out/graph.json ]; then
  say "  graphify has no graph for this repo yet -- build one before its MCP"
  say "  server or CLI can answer:"
  say "    graphify \"$TARGET\""
  say ""
fi

say "Files this run would create or change:"
if [ "$plan_serena" = "1" ]; then
  say "  + .serena/project.yml   (new)"
else
  say "  = .serena/project.yml   (exists -- left alone; this script does not rewrite it)"
fi
say "  ~ .code-intel.json      (manifest: the record of what was accepted)"
if [ "$plan_mcp" = "1" ]; then
  say "  + .mcp.json             (new: $mcp_servers -- absolute paths filled in for this machine)"
elif [ -f .mcp.json ]; then
  say "  = .mcp.json             (exists -- left alone; never merged. Add missing servers by hand:"
  say "                           references/mcp-wiring.md)"
fi
say ""
say "It will NOT touch: build files, compile databases, an existing .mcp.json,"
say "or anything not listed above. It never installs binaries."
say ""

# Diffs at propose time.
tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT

serena_yml_content() {
  cat <<EOF
# Written by /code-intel:setup. Edit freely -- this file is not rewritten on re-run.
languages: [$serena_languages]
ignore_all_files_in_gitignore: true
ignored_paths:
  - "**/node_modules"
  - "**/.venv"
  - "**/venv"
  - "**/build"
  - "**/dist"
  - "**/.build"
  - "**/DerivedData"
  - "**/target"
EOF
}

manifest_content() {
  local langs_json="" first=1 oldIFS
  oldIFS=$IFS; IFS=','
  for l in $serena_languages; do
    l=$(printf '%s' "$l" | tr -d ' ')
    [ -z "$l" ] && continue
    if [ "$first" = 1 ]; then langs_json="\"$l\""; first=0; else langs_json="$langs_json, \"$l\""; fi
  done
  IFS=$oldIFS
  local profiles_json="" pfirst=1
  for p in $profiles; do
    if [ "$pfirst" = 1 ]; then profiles_json="\"$p\""; pfirst=0; else profiles_json="$profiles_json, \"$p\""; fi
  done
  cat <<EOF
{
  "_comment": "Written by the code-intel plugin's /code-intel:setup. This is the reviewable record of what was accepted; re-running setup diffs against it. Safe to edit or delete.",
  "schemaVersion": 1,
  "generatedBy": "code-intel setup",
  "fingerprint": "$proposal_fingerprint",
  "profiles": [$profiles_json],
  "serena": {
    "languages": [$langs_json]
  },
  "lspPlugin": "code-intel-lsp"
}
EOF
}

mcp_json_content() {
  local first=1 b
  printf '{\n  "mcpServers": {\n'
  for b in $mcp_servers; do
    [ "$first" = "1" ] || printf ',\n'
    first=0
    case "$b" in
      serena)
        printf '    "serena": {\n      "command": "serena",\n      "args": ["start-mcp-server", "--project", "."]\n    }' ;;
      code-review-graph)
        printf '    "code-review-graph": {\n      "command": "code-review-graph",\n      "args": ["serve"],\n      "cwd": "%s"\n    }' "$TARGET" ;;
      graphify)
        printf '    "graphify": {\n      "command": "graphify",\n      "args": ["mcp", "%s/graphify-out/graph.json"]\n    }' "$TARGET" ;;
    esac
  done
  printf '\n  }\n}\n'
}

show_diff() {  # show_diff <path> <content-producing-function>
  local path="$1" fn="$2" new="$tmpdir/new"
  "$fn" > "$new" 2>/dev/null
  if [ -f "$path" ]; then
    if diff -u "$path" "$new" > "$tmpdir/d" 2>/dev/null; then
      say "  (no change) $path"
    else
      say "  --- diff: $path"
      sed 's/^/  /' "$tmpdir/d"
    fi
  else
    say "  --- new file: $path"
    sed 's/^/  | /' "$new"
  fi
  say ""
}

say "Diffs:"
[ "$plan_serena" = "1" ] && show_diff ".serena/project.yml" serena_yml_content
show_diff ".code-intel.json" manifest_content
[ "$plan_mcp" = "1" ] && show_diff ".mcp.json" mcp_json_content

# ------------------------------------------------------------------- apply ---
if [ "$WRITE" != "1" ]; then
  rule
  if [ "$unchanged" = "1" ]; then
    say "Nothing to do: .code-intel.json already records this exact proposal."
  else
    say "Nothing has been written. To apply:  /code-intel:setup --write"
  fi
  say "Then run /code-intel:doctor to verify the servers actually answer."
  rule
  exit 0
fi

if [ "$unchanged" = "1" ] && [ "$FORCE" != "1" ]; then
  say "Nothing to write: the manifest already records this proposal (use --force to rewrite)."
  say ""
  bash "$ROOT/scripts/code-intel-status.sh"
  exit 0
fi

# Atomic write with a single .bak. One backup, not a pile: the second run would
# otherwise overwrite the only copy of the pre-plugin original.
atomic_write() {  # atomic_write <path> <content-fn>
  local path="$1" fn="$2" dir tmp
  dir=$(dirname "$path")
  mkdir -p "$dir" 2>/dev/null || return 1
  tmp="$path.code-intel.$$"
  "$fn" > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  if [ -f "$path" ] && [ ! -f "$path.bak" ]; then
    cp -p "$path" "$path.bak" 2>/dev/null
    say "  backed up $path -> $path.bak"
  fi
  mv -f "$tmp" "$path" 2>/dev/null || { rm -f "$tmp"; return 1; }
  say "  wrote $path"
}

rule
say "Applying:"
[ "$plan_serena" = "1" ] && atomic_write ".serena/project.yml" serena_yml_content
atomic_write ".code-intel.json" manifest_content
if [ "$plan_mcp" = "1" ]; then
  atomic_write ".mcp.json" mcp_json_content
  say "  .mcp.json written -- Claude Code asks you to approve new MCP servers on"
  say "  next start; until you do, they are configured but not running."
fi
say ""

if [ -n "$missing_bins" ]; then
  say "Still missing (install these yourself -- this script never installs binaries):"
  for b in $missing_bins; do say "  $b: $(install_hint "$b")"; done
  say ""
fi

# Per-profile extras: the work that is NOT a config file, per stack.
say "Per-profile next steps:"
for p in $profiles; do
  case "$p" in
    ts)
      say "  [ts]    Ensure a 'typescript' dependency resolvable from the workspace, PINNED to ^5."
      say "          typescript@7 (the native rewrite) ships no lib/tsserver.js and"
      say "          typescript-language-server cannot use it (measured 2026-08-05)."
      say "          Monorepo: run 'tsc -b' once so referenced projects have .d.ts outputs,"
      say "          or cross-package reference searches under-report. See setup-typescript.md."
      ;;
    py)
      say "  [py]    Point the server at the project venv (pyrightconfig.json or"
      say "          [tool.basedpyright] venvPath/venv), or imports resolve against the"
      say "          wrong interpreter and references come back empty. No venv yet? Create"
      say "          one with 'uv venv' (never pip/venv). See setup-python.md."
      ;;
    cpp)
      say "  [cpp]   Generate a compile database -- clangd needs no build, but it needs this:"
      say "            cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
      say "            ln -sf build/compile_commands.json ."
      if [ -f package.xml ]; then
        say "          Colcon-style workspace detected: MERGE the per-package compile"
        say "          databases into one root-level file, or every package but one"
        say "          answers empty. See setup-cpp.md."
      fi
      say "          Verify: clangd --check=<file> --compile-commands-dir=<dir>"
      say "          Cross-compiling? --query-driver and an explicit target/sysroot are"
      say "          mandatory or clangd falls back to host headers. See setup-cpp.md."
      ;;
    swift)
      say "  [swift] References/implementations read a prebuilt index. Build the WHOLE"
      say "          workspace once, or the answers silently under-report symbols in"
      say "          unbuilt targets. A full native build can be multi-gigabyte -- if you"
      say "          operate under a memory cap, ask the human to run it. See setup-swift.md."
      ;;
  esac
done
say ""
say "Verification gate (do this before trusting any answer): run one known-answer"
say "query -- a symbol whose references you counted by hand -- and compare. A fresh"
say "checkout with no index returns empty for everything, and empty is"
say "indistinguishable from 'no callers'."
say ""
rule
bash "$ROOT/scripts/code-intel-status.sh"
say "Next: /code-intel:doctor"
exit 0
