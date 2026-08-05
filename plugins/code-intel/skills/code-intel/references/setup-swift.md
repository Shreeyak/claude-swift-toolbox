# Swift setup

## What "configured" means

The LSP tools read the response of `sourcekit-lsp`, which ships with the Xcode / Swift toolchain —
confirm it's reachable with `xcrun --find sourcekit-lsp`. For a SwiftPM package, no extra wiring is
needed: sourcekit-lsp reads `Package.swift` directly and works out of the box.

Everything past that depends on one fact: find-references, find-implementations, and
call-hierarchy do not walk the AST live — they read a **prebuilt index store** populated by
index-while-building. "Configured" means that index store exists and covers the code you're
querying, not just that the server started.

## The completeness gate (measured)

Because the index is build-derived, three consequences follow directly and all three have been
measured to bite:

**(a) A partial build causes silent under-reporting, not an error.** Build the whole
workspace/scheme once so the index spans every target and every local package before trusting a
references or implementations query. Benchmarked on a private Swift + C++ iOS repo, 2026-07,
macOS/Apple Silicon, Xcode toolchain + Homebrew LLVM: an implementations query for a protocol
returned only 3 of 9 known conformers, because the other 6 lived in packages that hadn't been
built yet. The query didn't error — it returned a confidently short list.

**(b) The index is keyed by workspace path.** Each git worktree has its own derived-data / index
location, so a query run from a worktree that hasn't been built there returns an empty or stale
index even if a sibling worktree's build is fully indexed.

**(c) A fresh checkout has no index at all**, and every query returns empty — indistinguishable
from "this symbol genuinely has no callers" until you check that a build has actually run.

**Memory-cap caveat:** a full workspace build can be multi-gigabyte and CPU/RAM-heavy. If you're
operating under a memory limit, ask the human to run the build rather than triggering an uncapped
native build yourself.

## Xcode-project (non-SwiftPM) setup

Package-manager projects need nothing extra (see above). A `.xcodeproj`/`.xcworkspace`-based
project needs a build-server bridge so sourcekit-lsp knows how the project actually compiles:

```bash
brew install xcode-build-server
xcode-build-server config -workspace <App>.xcworkspace -scheme <Scheme>
```

This writes `buildServer.json` — cheap, instant. It does **not** populate the index by itself;
follow it with one full build of that scheme (ask the human under a memory cap, per above) so
index-while-building actually runs.

`xcode-build-server config` is not a self-modifying installer — safe to run directly. `brew
install xcode-build-server` likewise, unless the environment forbids installs, in which case ask
the human.

## Trap: `.xcodeproj` vs `.xcworkspace` must match the real build (measured)

`-workspace <App>.xcworkspace` and `-project <App>.xcodeproj` hash to **different** derived-data
directories, even for the same app. If `xcode-build-server config` is pointed at the project while
the actual build in CI/Xcode uses the workspace (or vice versa), `buildServer.json` directs
sourcekit-lsp at an index that was never populated by the real build — every query returns 0
results, and nothing in the tool output says why.

Fix: use exactly whichever one (`-workspace` or `-project`) the project's real build invocation
uses. If unsure, check what a normal `xcodebuild` invocation or the CI config passes.

## Verification gate

1. Confirm the index data store directory is non-empty (its path is workspace/derived-data
   dependent — check whatever the current toolchain reports, e.g. via `xcodebuild
   -showBuildSettings` for `BUILD_DIR`/`INDEX_DATA_STORE_DIR`, or the SwiftPM `.build/index-store`
   for a package).
2. Pick a symbol you've counted call sites for by hand (grep it).
3. Run the LSP's find-references on that symbol and compare counts.
4. If short, suspect an incomplete build first (see (a) above) before doubting the tool.

Do this once per session before relying on LSP output for anything load-bearing.

## serena alternative

```yaml
languages: [swift]
ignored_paths:
  - "**/DerivedData/**"
  - "**/.build/**"
  - "**/Pods/**"
  - "**/Carthage/Build/**"
```

in `.serena/project.yml`. serena drives the same sourcekit-lsp/index-store stack underneath, so
every trap above applies identically — build first, check the index, then query.

## Gitignore list

`buildServer.json`, any generated compile databases, graph-tool output directories, and derived
data / `.build` index stores are all machine-specific build artifacts — gitignore them, don't
commit them.

## Blind spots

- **`#selector` / `@objc` runtime dispatch** — resolved by string at runtime; the LSP shows the
  declaration, not the dynamic call.
- **Key paths and string-keyed reflection** (`\.propertyName`, `NSObject.value(forKey:)`) — no
  static call-site link.
- **`@dynamicMemberLookup`** — subscript-based resolution, invisible as a named reference.
- **Protocol witnesses satisfied in an unbuilt module** — same root cause as the completeness gate;
  a conformance in a package that wasn't built simply isn't in the index.
- **Result builders** (`@resultBuilder`, e.g. SwiftUI's `ViewBuilder`) — the effective call graph
  is synthesized by the builder transform, not written literally at the call site.
- **Macros** — Swift macros expand at build time; the reference you actually want (the expanded
  code) exists only inside the build's macro-expansion cache, not in the source the LSP indexed.
- **SwiftUI previews** — preview-only code paths are a separate, often-unbuilt target.
- **Code behind inactive `#if` configurations** — same shape as C's `#ifdef` blind spot: not in
  the index if the active build configuration didn't compile that branch.

## Adjacent tools

When the index is known-incomplete (fresh checkout, unbuilt package) and a references query can't
be trusted yet, grep is a **completeness cross-check**, not a substitute answer: `: ProtocolName`
finds candidate conformers textually. It over-matches — inheritance and unrelated generic
constraints using the same token look identical — so use it to catch conformers the index missed,
not as the primary source of truth once the index is populated.

See also: `setup-cpp.md`, `setup-mixed-language.md`, `tools-catalog.md`.
