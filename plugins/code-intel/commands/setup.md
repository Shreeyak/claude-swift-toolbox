---
description: Detect this repo's stack and propose a code-intelligence setup (nothing is written until you say so)
argument-hint: "[--write]"
allowed-tools: Bash(bash:*), Read, Glob
---

Set up code intelligence for the current repository.

## How this command works

It is **propose-then-apply**. The default run changes nothing: it detects the
stack, prints the proposed configuration with a diff of every file it would
touch, and stops. Only `--write` applies it.

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-code-intel.sh" $ARGUMENTS
```

## What to do with the output

1. **Show the user the proposal verbatim.** The diffs are the point — do not
   summarise them away.
2. **If binaries are missing**, relay the install one-liners. Do **not** run
   them: this plugin never installs anything, and installers that modify the
   user's shell profile or agent configuration must be run by the human with an
   explicit shell escape.
3. **If the output flags an extension conflict** with an already-enabled
   single-language LSP plugin, stop and ask the user which one wins. First server
   registered for an extension wins and the other never starts — so this is a
   real conflict, not a harmless overlap. Do not guess on the user's behalf.
4. **Only re-run with `--write` after the user agrees.** Then walk through the
   printed per-profile next steps; several of them (generating a compile
   database, a full workspace build, pinning a `typescript` version) are the
   difference between a server that starts and a server that answers correctly.
5. **If the repo uses code-review-graph**, run `code-review-graph embed` once
   after the graph is built (ask first — it downloads the embedding model on
   first ever use). Without this step `semantic_search` silently falls back to
   keyword FTS over node names — the graph exists but concept search is lexical.
   Incremental afterwards: vectors are keyed by text hash, only changed nodes
   re-embed on the next `embed`.
6. **Finish with `/code-intel:doctor`** — a written config is not a working one.

## What it writes

- `.serena/project.yml` — only if absent; an existing one is left untouched.
- `.code-intel.json` — the manifest recording what was accepted. It is the
  idempotency key: a second `--write` against an unchanged proposal is a no-op.

Writes are atomic (temp file + rename) and keep a single `.bak` of any prior
file. If existing JSON config does not parse, the script **refuses** rather than
repairing it — relay that refusal, do not work around it by rewriting the file.

`.mcp.json` is deliberately **not** written: MCP entries carry machine-specific
absolute paths. See `references/mcp-wiring.md` in the `code-intel` skill.
