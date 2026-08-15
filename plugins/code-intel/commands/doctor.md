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
| 4. workspace | Does it have the artifact it reads? | per stack: a compile database for `clangd`, a resolvable `typescript` lib for `typescript-language-server`, the project venv for `basedpyright`, a populated index for `sourcekit-lsp` |
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

Depth per stack is in the `code-intel` skill's `references/setup-*.md`.
