# Dart / Flutter setup

## Read this first: on Dart, route around serena for "who calls this"

The single most important thing on this page, and it is more specific than "Dart semantic
navigation is unreliable" — that framing is wrong and was corrected on 2026-08-21.

Three tools were asked the same question about the same symbol on the same Flutter checkout. They
disagreed, and **the two that under-reported were serena and a scoped grep — not the Dart analysis
server.**

The symbol: the `AppButton` class declared at `lib/core/widgets/app_button.dart:3`.

**1. serena** (1.5.3, macOS/Apple Silicon), via its own bundled Dart SDK:

```
find_referencing_symbols(name_path="AppButton",
                         relative_path="lib/core/widgets/app_button.dart")
  -> 1 result: lib/core/widgets/app_button.dart, the class's own declaration.
     No external caller at all.
```

(Re-measured 2026-08-21 rather than quoted from notes. Note that serena's
`content_around_reference` numbers that line **17** where the file's own line numbering says
**18** — an off-by-one in its snippet rendering, not a second hit.)

**2. `grep -rn "AppButton(" lib/`** — finds the caller serena missed, but is scoped to `lib/`:

```
  lib/core/widgets/app_button.dart:18
  lib/presentation/pages/cell_counting/widgets/common_card_item.dart:105  <- serena missed this
```

**3. The Dart analysis server itself** — `dart language-server --protocol=lsp` (SDK 3.11.4) driven
directly over stdio, `textDocument/references` at the declaration, `includeDeclaration: true`:

```
  lib/core/widgets/app_button.dart:3                              <- the declaration
  lib/core/widgets/app_button.dart:18                             <- the const constructor
  lib/presentation/pages/cell_counting/widgets/common_card_item.dart:105   <- serena missed this
  test/screenshot_harness/component_screenshots_test.dart:152     <- the lib/-scoped grep missed this
```

Four references, all correct. So:

- **The under-report is in serena's Dart adapter, not in the Dart analysis server.** The server
  returns the caller serena drops, on the same files, on the same machine. The response is to
  route around serena for this question — *not* to distrust Dart tooling generally.
- **grep's blind spot here is scope, and it is easy to inflict on yourself.** Scoping to `lib/`
  lost a real reference in `test/`. Sweep the repo root.

**Calibration: this is one symbol.** The analysis server went 4-for-4 on `AppButton`; that is not
a general reliability claim, and the routing table's trust rules still apply to it like any other
semantic tool. Run the known-answer gate below on your own repo rather than inheriting this result.

### The order to use, on Dart

1. **The native LSP tool** — *conditional on `code-intel-lsp` being enabled for this project*
   (a per-project toggle) and on `pub get` having run. If it is not enabled here, this option does
   not exist and you start at step 2.
2. **A repo-root grep**, as the completeness cross-check — `grep -rn "ClassName(" .`, not
   `lib/`.
3. **serena last.** Never act on a serena "no callers" or short reference list for Dart on its own.
   Do not delete, rename, or refactor on the strength of one. serena remains fine here for
   `get_symbols_overview`, `find_symbol`, and symbol-level edits — it is specifically
   `find_referencing_symbols` that has been reproduced dropping a caller.

### On the root cause

Ruled out or weakened for the serena miss: **not** a wrong project root (the files are
byte-identical between the worktree and the main checkout, so either root gives the same answer);
**not** a cold-start race (a later call in the same long-running session returned the identical
short answer); **not** a missing `.dart_tool/package_config.json` (populated when the miss
reproduced). The leading remaining explanation is a scope-limited bug in serena's
`find_referencing_symbols`, matching the shape of serena issue #478 ("it was only finding
references within that class… Single-file bias") — filed against the **C# backend**, so this is a
**pattern match, not a confirmed root cause**. What is now confirmed is only the *locus*: serena's
side of the boundary, not Dart's.

## What "configured" means

1. `pubspec.yaml` exists at the project root. This is not cosmetic: the Dart Analysis Server
   locates a project root by **walking up from an open file looking for `pubspec.yaml`**, and a
   file with no `pubspec.yaml` ancestor is analyzed in isolation, with no cross-file resolution.
2. `.dart_tool/package_config.json` exists and is populated — this is what `pub get` writes, and
   it is how the analyzer resolves every `package:` import.
3. `.serena/project.yml` lists `dart` in `languages:` (for the serena path), and/or
   `code-intel-lsp` is **enabled for this project** (for the native LSP path).

**`code-intel-lsp` does declare a Dart server, as of 2026-08-21.** It launches the Dart SDK's own
analysis server:

```json
"dart": {
  "command": "dart",
  "args": ["language-server", "--protocol=lsp"],
  "diagnostics": false,
  "extensionToLanguage": { ".dart": "dart" }
}
```

`command` is the bare name `dart` deliberately, so it resolves through `PATH` — the Dart SDK
normally arrives inside Flutter, and `flutter/bin/dart` *is* the Dart SDK's `dart`. Do not
hardcode a path. If `dart` is not on `PATH`, add Flutter's `bin/` to it or read the SDK location
out of `flutter --version`. `--protocol=lsp` is already the default (see
`dart language-server --help`) and is passed explicitly so the declaration cannot change meaning
if that default moves.

If the LSP tool answers `No LSP server available for file type: .dart`, the plugin is disabled for
this project, predates the Dart entry, or `dart` is not on `PATH`.

**There is no pre-built index, and that is not a defect.** Unlike `clangd`'s compile database or a
Swift index store, the analysis server builds its element model **in memory at startup**, from
`pubspec.yaml` and `.dart_tool/package_config.json` plus the sources. A `--cache` flag can persist
a cache directory, but the authoritative state is in-process. The consequence to plan around:
**the first query after a cold start can return an empty list while analysis is still running.**
That is the semantic class's documented failure mode — a confident empty answer rather than an
error — showing up as a *timing* problem instead of a stale-index one. A careful client waits for
`$/analyzerStatus` to report `isAnalyzing: false`; from a tool call, just wait and retry once
before believing a zero.

**It tracks edits through LSP notifications, not by re-reading disk.** `textDocument/didOpen` /
`didChange` / `didClose` push edits in and it re-analyses incrementally. A change made by *another
process* — a `git checkout`, a rebase, another agent's write — is only picked up if the client
sends `workspace/didChangeWatchedFiles`.

> **Known staleness risk, unresolved.** `code-intel-lsp` is a declarative map: command, args,
> extension map, diagnostics flag, and nothing else. It has no code, so it neither sends nor can
> configure `workspace/didChangeWatchedFiles` — the entry schema has no knob for it. Whether
> Claude Code's built-in LSP client sends those notifications was **not verified**. Until someone
> checks, treat a Dart answer taken after an out-of-band file change as possibly stale; re-open
> the file or restart the session.

## Install

- **serena** — `uv tool install serena-agent`. On Apple Silicon add
  `-p cpython-3.13-macos-aarch64-none`, or a stray x86_64 Python cross-builds `cryptography` and
  fails (see `tools-catalog.md`).
- **The Dart analysis server needs no separate install**: it ships inside the Dart SDK, which
  ships inside Flutter. Put Flutter's `bin/` on `PATH` (`dart --version` should answer), or
  install Dart on its own from <https://dart.dev/get-dart>. Verified on Dart SDK 3.11.4 —
  `initialize` completes in roughly 450 ms and advertises `referencesProvider`,
  `definitionProvider`, `implementationProvider`, `renameProvider` and `callHierarchyProvider`,
  all true.
- **serena brings a second, different Dart SDK.** serena downloads and pins its **own** Dart SDK for
  the language server, independent of whatever Dart/Flutter SDK is on `PATH`. The default pin is
  Dart SDK `3.7.1`; it lands under `~/.serena/language_servers/static/DartLanguageServer/dart-sdk/`
  (note the `static/` path segment). Check the version it actually fetched with:

  ```bash
  cat ~/.serena/language_servers/static/DartLanguageServer/dart-sdk/version
  ```

  This will routinely differ from `dart --version` on `PATH`. That mismatch is normal and is not
  known to cause the under-report above — it has not been tested either way.

  To pin serena's server to the project's own toolchain instead, set in `.serena/project.yml`:

  ```yaml
  ls_specific_settings:
    dart:
      dart_sdk_version: "3.11.4"   # match `dart --version` on PATH
  ```

  Only do this if a known-answer probe shows drift you can attribute to the version. It costs an
  SDK download.

## Per-project setup

`/code-intel:setup` writes this for you. The Flutter variant:

```yaml
languages: [dart]
ignore_all_files_in_gitignore: true
ignored_paths:
  - "**/build"
  - "build/"                 # see the anchoring note below
  - ".dart_tool/"
  - "**/ephemeral/"          # Flutter iOS/macOS/Windows generated build scratch
  - "android/.cxx/"          # only when the project has a native android/ tree
  # - "**/*.g.dart"          # see the generated-code judgment call below
  # - "**/*.freezed.dart"
```

**Why both `**/build` and `build/`.** Under gitignore semantics an unanchored pattern matches at
any depth and the two are equivalent. Under an fnmatch-style matcher, `**/` can require at least
one preceding path segment — in which case `**/build` would *not* match a top-level `build/`.
Which matcher serena applies to `ignored_paths` was not verified. Flutter's top-level `build/` is
routinely multiple gigabytes, so both forms are listed rather than resolving the ambiguity: one
redundant line is cheaper than an accidental multi-gigabyte index.

**Pure Dart vs Flutter.** A Flutter package's `pubspec.yaml` has a top-level `flutter:` key (and a
`flutter: sdk: flutter` entry under `dependencies:`); a pure Dart package has neither. A pure Dart
package produces none of `**/ephemeral/`, `android/.cxx/`, so **drop those lines there** — they
are Flutter build artifacts, not Dart ones. The `build` entries and `.dart_tool/` apply to both.

**The generated-code judgment call.** `*.g.dart` and `*.freezed.dart` (from `build_runner`,
`json_serializable`, `freezed`, `drift_dev`) are left **out** of `ignored_paths` by default.
Ignoring them removes generated noise from results, but it also makes serena unable to resolve
references that only exist inside generated code — and on a codebase that leans on codegen, those
are real callers. This is a per-project decision, not a recommendation: it was never probed
against a symbol whose only references live in generated output. Decide deliberately rather than
inheriting a default silently.

## The `pub get` precondition — and `flutter` vs `dart`

Run the package manager **before any query**, or `package:` imports do not resolve and every
reference query comes back short:

- Flutter project (top-level `flutter:` key) → **`flutter pub get`**
- Pure Dart package → **`dart pub get`**

Using `dart pub get` on a Flutter project misresolves the `flutter` SDK dependency itself, because
that project's `environment.sdk` and its `flutter: sdk: flutter` dependency assume the Flutter
SDK's package resolution. Get this the wrong way round and the failure is a short answer, not an
error.

## Known-answer gate

Do this once per repo before trusting anything, and note that on Dart it is not optional
ceremony — it is how you find out how bad the under-report is *here*:

1. Pick a widget or class you know is used across files — for a Flutter app, a shared button or
   card widget is ideal.
2. `grep -rn "ClassName(" .` — **from the repo root, not `lib/`.** Scoping to `lib/` is what lost
   the `test/` reference in the measurement above; scope it and your baseline count is wrong
   before you start. Count the real call sites by eye.
3. Ask the **native LSP tool** for references on the same symbol (needs `code-intel-lsp` enabled
   here). If it returns zero for everything, wait a few seconds and ask once more — a cold
   analysis server and an unindexed one look identical.
4. Ask **serena** `find_referencing_symbols` for the same symbol.
5. Compare all three counts and write them down. **If serena returns only the declaring file while
   the LSP tool returns the cross-file callers, you have reproduced the adapter defect here** —
   from then on treat serena's Dart reference answers in this repo as a lower bound, and prefer
   the LSP tool. If *both* semantic tools come in under the grep count, that is a different and
   more serious finding: report it rather than picking whichever number you liked.

## Traps

- **Pub workspaces vs plain path dependencies are different things.** A formal Pub workspace (an
  explicit `workspace:` field in the root `pubspec.yaml`) produces a single shared
  `.dart_tool/package_config.json`. A plain local `path:` dependency is not a Pub workspace, but
  ordinary resolution already puts both packages in one `package_config.json`, so the
  single-analysis-context benefit applies anyway. Don't conflate them when reading Dart docs:
  opening a multi-package root *without* either arrangement creates a separate analysis context
  per package and raises memory use.
- **serena's Dart SDK is not your Dart SDK.** See Install above. Version drift between the two is
  the normal state.
- **A git worktree needs its own `.serena/project.yml`** — and that alone does not register it
  with serena. This is language-independent; see the worktree section of `mcp-wiring.md`.
- **Empty is not "no callers."** Standard semantic-tool caveat, and on Dart it has two distinct
  causes that look identical: serena's adapter dropping references, and an analysis server that is
  simply still warming up. Distinguish them by retrying, and by asking the other tool.
- **Two different Dart servers may be answering you.** The native LSP tool runs the `dart` on your
  `PATH`; serena runs its own pinned SDK download. When two tools disagree about a Dart symbol,
  that is one of the reasons — check both versions before assuming one is broken.

## Blind spots

Beyond the reproduced under-report, these are Dart/Flutter-specific things a semantic reference
query will not surface on its own:

- **Generated code** (`*.g.dart`, `*.freezed.dart`) — the reference exists in a file produced by
  `build_runner`. If codegen has not run, the call site does not exist yet to be found.
- **`dart:mirrors` and annotation-driven registration** — DI containers and serializers that wire
  types up by annotation resolve at build or run time, with no static call-site link.
- **`noSuchMethod` forwarding** — dynamic dispatch with no named reference at the call site.
- **Extension methods** — the call reads as an ordinary method call on the receiver; which
  extension supplies it depends on what is imported in that file.
- **`dynamic`-typed receivers** — every method call on a `dynamic` is resolved at runtime, so no
  static reference is recorded.
- **String-keyed navigation and asset lookups** — named routes (`Navigator.pushNamed`), asset
  paths, and `MethodChannel` names are strings. grep is the only tool for these, and that is its
  lane, not a downgrade.
- **Conditional imports** (`import ... if (dart.library.io) ...`) — only the branch matching the
  analyzed platform configuration is in the index.

## Adjacent tools

`grep`/`rg` is the completeness cross-check here and carries real weight, but sweep the repo root,
not `lib/` — see the top of this page. `ast-grep` supports Dart-shaped structural queries if you need "every `setState` inside a loop"
rather than "who calls X". `dart analyze` answers correctness questions, not navigation ones. The
official Dart MCP Server (`dart_mcp_server`) is **not** a navigation alternative: its `lsp` tool
exposes only `hover`, `signatureHelp`, and `resolveWorkspaceSymbol` — no references, no
definition, no call hierarchy, no rename.

See also: `setup-generic.md`, `mcp-wiring.md`, `tools-catalog.md`.
