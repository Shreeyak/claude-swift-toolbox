---
description: Diagnose code intelligence in this repo — what is configured, what is missing, and whether the semantic tools actually answer
allowed-tools: Bash(bash:*), Read, Glob, Grep
---

Diagnose this repository's code-intelligence setup and report per-failure fixes.

This command is **diagnostics, not enforcement**. It changes nothing.

## Step 1 — machine-checkable state

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/code-intel-status.sh" --verbose
```

## Step 2 — walk the state model

A tool is only useful at the last rung. Report where each one actually stands,
and stop at the first rung that fails — the later rungs are meaningless below it.

| Rung | Question | How it is checked |
|---|---|---|
| 1. binary | Is the server/tool on `PATH`? | the status script above |
| 2. started | Does the process launch at all? | invoke an LSP tool once, then check the `/plugin` **Errors** tab — start failures surface there, not in the tool result |
| 3. initialized | Did it complete LSP initialize? | same place; a server that spawns and dies mid-handshake looks identical to one that never spawned |
| 4. workspace | Does it have the artifact it reads? | per stack: a compile database for `clangd`, a resolvable `typescript` lib for `typescript-language-server`, the project venv for `basedpyright`, a populated index for `sourcekit-lsp`, a `pubspec.yaml` plus a `.dart_tool/package_config.json` populated by `pub get` for `dart` — the last builds its model in memory at startup, so give it a moment before rung 5 |
| 5. probe | Does it return a **correct known answer**? | you run it — see below |

**Rung 5 cannot be done from a shell script, and this plugin does not pretend
otherwise.** A bash script cannot speak LSP, so nothing in `scripts/` can tell a
working server from a server that starts cleanly and answers wrongly. The probe
is therefore *your* job as the agent:

1. Pick a symbol in this repo whose call sites you can count by hand — read the
   file, count the references yourself first.
2. Ask the semantic tool for its references (the native LSP tool, or serena's
   `find_referencing_symbols`).
3. Compare. **Fewer than you counted = the index is incomplete**, which is the
   dangerous failure: it returns a confident empty or short answer, never an
   error. **Zero for everything = no index at all.**
4. Report the counts you compared, not just "it works".

This rung exists because rung 1 does not retire the problem. `clangd` with no
compile database starts fine and answers wrongly. A fresh checkout's Swift index
is empty and every query returns nothing. Both look healthy from the outside.

## Step 3 — report

For each tool: its rung, and if it stopped short, the one-line fix. Common fixes:

| Symptom | Fix |
|---|---|
| Binary missing | the install one-liner from `/code-intel:setup`; never install it for the user |
| `.mcp.json` launches a server through an ephemeral runner (`uvx …`) | point it at the installed binary — the runner rebuilds its environment each launch and stalls at "connecting…" |
| `.mcp.json` names a binary that is not on `PATH` | install it, then reload the session |
| Graph file referenced but absent | rebuild the graph, or remove the stale entry |
| `semantic_search` results look lexical (only name matches, no near-synonyms) | the repo's graph.db has no `embeddings` table — `semantic_search` is silently falling back to keyword FTS. Run `code-review-graph embed`. Check: `sqlite3 .code-review-graph/graph.db ".tables" \| grep -q embeddings` |
| `clangd` answers empty for a file | that file is not in the compile database — check `clangd --check=<file> --compile-commands-dir=<dir>` |
| TypeScript server starts then dies | no resolvable `typescript` lib, or `typescript@7` is installed: pin `^5` |
| Two plugins claim the same extension | first registered wins, the other never starts — disable one, explicitly |
| Swift references under-report | only part of the workspace was built; build it whole (ask the human if you are under a memory cap) |
| **Dart references under-report via serena** | **known defect in serena's Dart adapter, not fixable from config.** Reproduced: `find_referencing_symbols` returned exactly one result (the symbol's own declaration), dropping a real cross-file caller — while `dart language-server` returned that same caller correctly. Ask the native LSP tool instead (needs `code-intel-lsp` enabled here); cross-check with a repo-root grep. Never act on a serena Dart "no callers" answer alone. See `setup-dart.md` |
| Dart references empty for everything | two different causes, check in this order. **(1) Cold server** — the Dart analysis server builds its model in memory at startup and answers empty while still analysing. Wait a few seconds and retry once *before* concluding anything. **(2) No `pub get`** — `.dart_tool/package_config.json` absent or stale. Use `flutter pub get` for a project with a top-level `flutter:` key, `dart pub get` otherwise |
| Dart answers went stale after an external change | the analysis server tracks edits through LSP notifications, not by polling disk. A `git checkout`/rebase/another process's write is only seen if the client sends `workspace/didChangeWatchedFiles`, which `code-intel-lsp` cannot configure. Re-open the file, or restart the session, after an out-of-band change |
| `No LSP server available for file type: .dart` | the `code-intel-lsp` plugin is not enabled for this project, or predates the Dart entry (added 2026-08-21), or `dart` is not on `PATH` — it ships inside Flutter, so put Flutter's `bin/` on `PATH` |
| Worktree sees the wrong project | serena resolves its project once, from cwd, at startup, and does not auto-register worktrees. Start the session with cwd inside the worktree; see `mcp-wiring.md` |

Depth per stack is in the `code-intel` skill's `references/setup-*.md`.

**Dart note for rung 5.** The known-answer probe is not optional ceremony on a Dart repo — it is
how you find out whether the under-report above is happening *here*. Count a widget's call sites
with `grep -rn "ClassName(" .` — **sweep the repo root, not `lib/`**: a `lib/`-scoped grep was
measured missing a real caller in `test/`, so scoping it makes grep under-report too and you lose
your reference count. Then ask each semantic tool the same question and compare all three numbers.
If serena returns only the declaring file while the native LSP tool returns the callers, you have
reproduced the adapter defect — report that explicitly rather than reporting the tool green.

Rung 5 also has a Dart-specific false negative: **"zero for everything" is what a cold analysis
server looks like**, not only what an unindexed one looks like. Retry once after a pause before
recording a zero.
