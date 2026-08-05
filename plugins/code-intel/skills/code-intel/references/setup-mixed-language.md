# Mixed-language / cross-boundary setup

This is an **evidence-gathering workflow for crossing a language boundary**, not a description of
a unified index. No tool in this plugin's router indexes two languages as one graph by default.
For any cross-language reference question, first classify which of three situations you're in,
then apply that situation's procedure. State which situation an answer came from — a
cross-boundary claim without that label is not verified.

## The three situations

### 1. Name-match crosses the boundary

The exported symbol keeps an **identical name** on both sides: `extern "C"` symbols, direct C
interop, an FFI declaration that names the C symbol literally.

**Procedure:** grep, or a tree-sitter graph (code-review-graph, graphify), is sufficient and
complete *over text* — the name is the same string on both sides, so textual matching is not an
approximation here. Use each side's own LSP (clangd / sourcekit-lsp / etc., per
`setup-cpp.md`/`setup-swift.md`) for the per-side call sites once you've located the shared name.

**Trap:** breaks the instant anything renames across the boundary — mangled C++ names (C++ has no
stable ABI-visible name without `extern "C"`), an FFI layer that re-exports under a different
symbol, or generated bindings that rewrite the name (camelCase↔snake_case, prefix injection).
Confirm the name is *actually* identical before trusting a grep match as complete.

### 2. A shared semantic index crosses it

One toolchain indexes **both** languages into a single build, so a reference genuinely resolves
across the boundary semantically, surviving interop renaming. The concrete example on this stack:
a Swift + C++/Objective-C project built by the Xcode toolchain — sourcekit-lsp reads the same
index store the native (clangd-indexable) code was indexed into, so a Swift call site of a C++
symbol is resolvable even if the interop layer renamed it.

**Procedure:** build the whole workspace once (see `setup-swift.md`'s completeness gate — the same
partial-build under-reporting applies here, doubled, since now two languages depend on the same
build having run to completion). Query from whichever side's server reads the shared index.

State plainly: this is the **only** one of the three situations where a single query answers a
cross-boundary reference question directly. It depends entirely on the build system actually
producing one shared index — if the build is split (e.g. the C++ library is prebuilt separately
and only its headers are vended), you're back in situation 1 or 3.

### 3. Nothing crosses it

The common case: a binding layer that registers names at **runtime** or via a **macro/codegen
DSL** — Python↔C++ via a binding library, JNI, N-API, WASM imports, gRPC/IDL-generated stubs.
Neither an LSP nor a name-match graph traverses this, because the association between the two
sides exists only inside the binding-registration call, frequently as a bare string literal that
no static tool treats as a reference.

**Procedure, as explicit steps:**

1. **Locate the binding-registration site textually.** Grep the string literal of the exposed
   name (e.g. the name argument to a `def(...)`/`register(...)`/`@JNIEXPORT`-style call).
2. **Read that site** to recover the mapping `exposed-name → native symbol`. This mapping lives
   only in source text — no tool computes it for you.
3. **Run a semantic query on each side separately**, against its own native symbol, using that
   side's own LSP/graph per `setup-cpp.md` / `setup-swift.md` / the relevant sibling doc.
4. **State in the answer that the two halves were joined by a textual mapping you read, not by a
   resolver**, and that a second registration site elsewhere in the codebase would be missed
   unless every registration call was swept. One binding site found is not proof it's the only
   one — grep for the registration *pattern* (the macro or function name), not just the one
   instance you found first.

## Boundary kind → tool table

| Boundary kind | What crosses | Primary tool | Required cross-check |
|---|---|---|---|
| `extern "C"` / direct FFI, identical name | The literal symbol name | grep or a tree-sitter graph | Confirm the name truly is unmangled/unrenamed on both sides |
| Single-toolchain shared index (e.g. Swift+C++ via Xcode) | Semantic reference | The side's LSP reading the shared index | Full workspace build completed (situation 2's procedure) |
| Runtime/macro-DSL binding registration (Python↔C++, JNI, N-API, WASM, gRPC/IDL) | Nothing, automatically | grep the registration site, then per-side LSP | Sweep for *all* registration call sites, not just the first found |
| Generated code (proto/IDL/schema-derived) | Nothing past the generator | Grep the generator input | Treat generated output as non-authoritative; see below |

## Two LSPs, one per language: extension ownership must not overlap

Each language server in this plugin's map claims a fixed, disjoint set of extensions. In the
companion LSP plugin's map, `.h` is claimed by clangd (headers are C/C++ territory even in a mixed
Swift project) and the Swift server claims only `.swift`. If a repo's setup causes two servers to
both try to own the same extension, one of them silently never starts for that extension — check
the companion plugin's own documentation for the authoritative extension list before assuming a
given file type is covered.

## Generated code

Whichever side of the boundary is generated (protobuf/gRPC stubs, IDL-derived bindings, schema
codegen), the generator's **input** — the `.proto`, IDL file, or schema — is the real source of
truth for what the boundary exposes. A reference search that stops at the generated output file is
incomplete: it finds where the generated symbol is used, not why it exists or what upstream schema
change would alter it. Grep the generator input (the schema/IDL file) for the field or method name,
not just the generated `.pb.cc`/`.pb.swift`/equivalent output.

## Blind spots summary

- Any renamed/mangled symbol crossing a name-match boundary (situation 1's trap).
- Any incomplete build feeding a shared-index boundary (situation 2 inherits situation 2's own
  build-completeness gate, and now for two languages at once).
- Any registration call site not swept when working situation 3 — grep finding one occurrence is
  not evidence it's the only one.
- Generated code whose upstream schema changed but whose generated output wasn't regenerated yet —
  a stale generated file answers for a boundary that no longer matches its source.

**The rule:** any cross-boundary reference answer must name which of the three situations
(name-match / shared-index / nothing-crosses) it came from. An answer that doesn't is unverified,
regardless of how confident the underlying tool sounded — recall the general trust-calibration
rule that a graph or LSP's "0 impacted" can be a false negative, and that risk compounds at a
language boundary.

See also: `setup-cpp.md`, `setup-swift.md`, `setup-python.md`, `tools-catalog.md`, and the
`code-intel-lsp` plugin's own README for the authoritative per-extension server ownership list.

When in doubt about which situation applies, default to the more conservative one: treat an
unverified name match as situation 1 (grep + per-side LSP), not situation 2, until a shared build
and shared index are confirmed to actually exist for that pair of files.
