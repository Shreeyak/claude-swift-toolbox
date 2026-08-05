# `code-intel-lsp`

Four language servers declared to Claude Code in **one togglable plugin** instead
of four: `typescript-language-server`, `basedpyright-langserver`, `clangd`, and
`sourcekit-lsp`. When a server's binary is present, goto-definition and
find-references appear as **native tools** — no MCP wiring, no approval step, no
working-directory binding.

Companion to the [`code-intel`](../code-intel/README.md) plugin, which supplies
the routing knowledge, the setup command, and the doctor. They are separate
plugins so the language-server map can be toggled per project independently of
the (much cheaper) router and hooks.

```bash
claude plugin install code-intel-lsp@claude-swift-toolbox
```

## Why one plugin instead of four

The problem this solves is operational, not technical: four singleton plugins
mean four enable/disable toggles to keep in sync per project, and four places to
look when navigation stops working. One map, one toggle, one place.

## Lifecycle — measured, not assumed

Measured 2026-08-05 on a machine with all four binaries installed (the worst
case), using a probe plugin carrying this exact map, loaded into headless
sessions across several fixtures with a 1 Hz process sampler:

| Fixture / workload | Server spawned? |
|---|---|
| Empty repo, trivial prompt | **none** |
| TypeScript repo, read + edit workload | **none** — edits alone start nothing |
| Python repo, explicit LSP tool call | basedpyright at the tool call, ~17 MB RSS, correct answer, process gone after session exit |
| TypeScript repo (with `typescript@5.9`), LSP tool call | typescript-language-server at the tool call, ~45 MB RSS, correct answer, clean exit |

**Activation is lazy**: a server starts on the first LSP tool invocation touching
its file type, not at plugin load. Repos where the tools go unused spawn nothing.
Cleanup on session exit was complete in every run. Measured in headless mode;
interactive behaviour was corroborated indirectly (a server errored only at LSP
call time, the same lazy pattern).

`diagnostics: false` on every entry means no server spawns on ordinary edits
either — the config is cheap twice over. Navigation is unaffected by this
setting. Diagnostics can be enabled per server once the context volume of four
servers pushing diagnostics after every edit has actually been measured; it has
not been.

**A present binary is not a working server.** Two failures reproduced in one
afternoon of measurement: `tsserver` needs a resolvable `typescript` library
(a bare repo fails at initialize), and `typescript@7` — the native rewrite —
ships no `lib/tsserver.js` at all, so `typescript-language-server` cannot use it
(pin `typescript@^5`). This is exactly what `/code-intel:doctor`'s known-answer
probe exists to catch.

## Provenance

Every entry is derived from a first-party single-language LSP plugin in the
official Claude Code plugin marketplace, inspected 2026-08-05. That marketplace
carries no aggregate version, so the **per-plugin** version is the pin.

| Server | Derived from | Overrides applied | Why |
|---|---|---|---|
| `typescript` | `typescript-lsp@1.0.0` | `diagnostics: false` | unmeasured context volume with four servers |
| `basedpyright` | `pyright-lsp@1.0.0` | `command` → `basedpyright-langserver`; `diagnostics: false` | basedpyright is a maintained fork with stricter defaults and the same LSP surface; either works |
| `clangd` | `clangd-lsp@1.0.0` | `diagnostics: false`; added `.m` → `objective-c`, `.mm` → `objective-cpp` | Objective-C/C++ is clangd's territory and upstream omits it |
| `sourcekit-lsp` | `swift-lsp@1.0.0` | `diagnostics: false` | as above |

Extension maps, commands, and args are otherwise **verbatim upstream**,
deliberately: upstream values are the ones that get fixed when they are wrong.
Notably `.h` maps to `"c"` (not `"cpp"`) because that is the upstream value —
do not "improve" it here.

**At each release**, diff this map against the current official single-language
plugin configs, so an upstream fix is not silently lost.

## Extension ownership

`.h` is owned by **clangd**, and `sourcekit-lsp` claims only `.swift`. That is a
stated policy, not a repair of an upstream collision — upstream's Swift plugin
never claimed `.h` either. It matters because within a single `lspServers` map
two servers must not claim the same extension: the first registered wins and the
other never starts for it.

The same rule applies **across** plugins, and there it is a real conflict:

> If a single-language LSP plugin is already enabled for any of these extensions,
> the first server registered wins and the other never starts. `/code-intel:setup`
> surfaces the collision and requires an explicit choice — disable the singletons,
> or do not enable this plugin here. Coexistence is not benign.

A server whose binary is absent is skipped gracefully and, since Claude Code
2.1.205, does **not** claim its extensions — so another plugin's working server
for the same extension still functions.

## Not supported here

Deliberately out of scope; use a dedicated plugin or serena:

- **Vue** (`.vue`) — needs the Vue language server, not `typescript-language-server`
- **Deno** (`deno lsp`) — a different server for the same extensions; enabling
  both would collide
- **Notebooks** (`.ipynb`) — not a plain-text LSP document
- **Alternate Python servers** — `pyright-langserver`, `pylsp`, `jedi-language-server`
  all claim `.py`; pick one
- **Every other language** — Go, Rust, JVM, C#, Ruby, PHP, Lua and the rest stay
  with their official single-language plugins or with serena. See
  `setup-generic.md` in the `code-intel` skill's references.

## Platform

macOS and Linux. The servers themselves are cross-platform, but this
marketplace's accompanying scripts are bash and are not tested on Windows.
