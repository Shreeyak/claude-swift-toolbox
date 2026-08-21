# `code-intel-lsp`

Five language servers declared to Claude Code in **one togglable plugin** instead
of several: `typescript-language-server`, `basedpyright-langserver`, `clangd`,
`sourcekit-lsp`, and Dart's `dart language-server` — the last added 2026-08-21,
the only entry with no upstream counterpart and no lifecycle measurement, so read
**The Dart entry** below before relying on it. (Only four of the five have an
upstream singleton plugin to consolidate; see **Why one plugin instead of
several** below.)
When a server's binary is present, goto-definition and
find-references appear as **native tools** — no MCP wiring, no approval step, no
working-directory binding.

Companion to the [`code-intel`](../code-intel/README.md) plugin, which supplies
the routing knowledge, the setup command, and the doctor. They are separate
plugins so the language-server map can be toggled per project independently of
the (much cheaper) router and hooks.

```bash
claude plugin install code-intel-lsp@claude-swift-toolbox
```

## Why one plugin instead of several

The problem this solves is operational, not technical: the four servers that
*do* have upstream singleton plugins would otherwise mean four enable/disable
toggles to keep in sync per project, and four places to look when navigation
stops working. One map, one toggle, one place. Dart — the fifth entry — has no
singleton plugin to consolidate; it is here because nothing else ships it.

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
setting. Diagnostics can be enabled per server once the context volume of five
servers pushing diagnostics after every edit has actually been measured; it has
not been.

**A present binary is not a working server.** Two failures reproduced in one
afternoon of measurement: `tsserver` needs a resolvable `typescript` library
(a bare repo fails at initialize), and `typescript@7` — the native rewrite —
ships no `lib/tsserver.js` at all, so `typescript-language-server` cannot use it
(pin `typescript@^5`). This is exactly what `/code-intel:doctor`'s known-answer
probe exists to catch.

## Provenance

Every entry **except `dart`** is derived from a first-party single-language LSP
plugin in the official Claude Code plugin marketplace, inspected 2026-08-05.
That marketplace carries no aggregate version, so the **per-plugin** version is
the pin.

| Server | Derived from | Overrides applied | Why |
|---|---|---|---|
| `typescript` | `typescript-lsp@1.0.0` | `diagnostics: false` | unmeasured context volume with four servers |
| `basedpyright` | `pyright-lsp@1.0.0` | `command` → `basedpyright-langserver`; `diagnostics: false` | basedpyright is a maintained fork with stricter defaults and the same LSP surface; either works |
| `clangd` | `clangd-lsp@1.0.0` | `diagnostics: false`; added `.m` → `objective-c`, `.mm` → `objective-cpp` | Objective-C/C++ is clangd's territory and upstream omits it |
| `sourcekit-lsp` | `swift-lsp@1.0.0` | `diagnostics: false` | as above |
| `dart` | **nothing — no upstream `dart-lsp` exists** | n/a; authored here | see below |

Extension maps, commands, and args are otherwise **verbatim upstream**,
deliberately: upstream values are the ones that get fixed when they are wrong.
Notably `.h` maps to `"c"` (not `"cpp"`) because that is the upstream value —
do not "improve" it here.

`dart` is the exception to that rule and the only entry authored here. The
official marketplace was re-inspected 2026-08-21 and ships `clangd-lsp`,
`csharp-lsp`, `gopls-lsp`, `jdtls-lsp`, `kotlin-lsp`, `liquid-lsp`, `lua-lsp`,
`php-lsp`, `pyright-lsp`, `ruby-lsp`, `rust-analyzer-lsp`, `sourcekit-lsp`,
`swift-lsp` and `typescript-lsp` — **no `dart-lsp`**. There is therefore no
upstream config to diff this row against at release time, and equally no
first-party plugin that could collide with it over `.dart`.

**At each release**, diff this map against the current official single-language
plugin configs, so an upstream fix is not silently lost.

## The Dart entry

Added 2026-08-21. Read this before relying on it — it differs from the other four
in three ways that matter operationally.

```json
"dart": {
  "command": "dart",
  "args": ["language-server", "--protocol=lsp"],
  "diagnostics": false,
  "extensionToLanguage": { ".dart": "dart" }
}
```

**The binary comes from the Dart SDK, which normally arrives inside Flutter.**
`command` is the bare name `dart` **on purpose**: it resolves through `PATH`, so
whichever SDK the developer already uses is the one that answers. Do not hardcode
a path here — on the machine this was authored on, `dart` resolves to
`/Users/shrek/software/flutter-3.35.7/bin/dart` (Dart SDK 3.11.4), which is
Flutter's bundled copy, and that location is specific to that install. If `dart`
is not on `PATH`, either add Flutter's `bin/` to it or read the SDK path out of
`flutter --version`. A missing binary is skipped gracefully, as with every other
entry. `--protocol=lsp` is already the default (confirmed in
`dart language-server --help`); it is passed explicitly so the map does not
silently change meaning if that default ever moves.

**There is no pre-built index, and that is not a defect.** Unlike `clangd`'s
compile database or a Swift index store, the Dart analysis server builds its
element model **in memory at startup**, from `pubspec.yaml` and
`.dart_tool/package_config.json` plus the source tree. A `--cache` flag can
persist a cache directory, but the authoritative state is in-process. Two
consequences: `pub get` must have run (no `package_config.json` means no
resolution), and **the first query after a cold start can return an empty list
while analysis is still running**. That is the semantic class's documented
failure mode — a confident empty answer, not an error — arriving here as a
*timing* problem rather than a stale-index one. A well-behaved client waits for
`$/analyzerStatus` to report `isAnalyzing: false` before believing an empty
result.

**It tracks edits through LSP notifications, not by re-reading disk.**
`textDocument/didOpen` / `didChange` / `didClose` push edits into the server and
it re-analyses incrementally. Files changed on disk by *another process* — a
`git checkout`, a rebase, another agent's write — are only picked up if the
client sends `workspace/didChangeWatchedFiles`.

> **Known staleness risk, unresolved.** This plugin is a declarative map: it
> supplies a command, args, an extension map and a diagnostics flag, and nothing
> else. It contains no code, so it neither sends nor can configure
> `workspace/didChangeWatchedFiles` — the entry schema has no knob for it.
> Whether Claude Code's built-in LSP client sends those notifications was **not
> verified** while authoring this entry. Until someone checks, treat Dart answers
> after an external file change as possibly stale, and force a re-read of a file
> you have reason to think moved under the server.

**Lifecycle is unmeasured for this entry.** The table above is a 2026-08-05
measurement with the *four* original binaries installed; Dart was not in it. The
lazy-activation and clean-exit behaviour is expected to be identical because it
is a property of the host, not of the server — but expected is not measured, and
this README does not claim otherwise.

**What was verified**, driving `dart language-server --protocol=lsp` directly
over stdio against a Flutter repo on 2026-08-21: `initialize` completes in about
450 ms and advertises `referencesProvider`, `definitionProvider`,
`implementationProvider`, `renameProvider` and `callHierarchyProvider`, all
true; `textDocument/references` on a widget class returned all four real
references including one in `test/` and one that serena's Dart adapter drops.
See `setup-dart.md` in the `code-intel` skill's references for that comparison
and the routing rule it implies.

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

Dart **was** on this list and was removed on 2026-08-21. The reason it was listed
— "use the official single-language plugin instead" — turned out not to apply,
because no official Dart plugin exists to defer to, while the SDK ships a
perfectly good server. See **The Dart entry** above.

## Platform

macOS and Linux. The servers themselves are cross-platform, but this
marketplace's accompanying scripts are bash and are not tested on Windows.
