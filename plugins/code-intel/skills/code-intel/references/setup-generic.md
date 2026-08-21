# Setup: any other language

For a language not covered by the five bundled servers in `code-intel-lsp`
(typescript-language-server, basedpyright, clangd, sourcekit-lsp, dart) — Go, Rust, JVM
languages, .NET, Ruby, PHP, Lua, and everything else with a language server.

**Dart/Flutter is not covered by this page — read `setup-dart.md` instead.** Dart *does* have a
bundled server (`code-intel-lsp` declares the Dart SDK's own `dart language-server`), so path (b)
below already applies to it, and it carries a measured caveat about serena's Dart adapter that
this generic page does not cover.

## Two paths

**(a) serena.** Ships with support for many languages beyond the five bundled ones. Add a
`languages:` entry to `.serena/project.yml` and index the project — see the minimal config below.
This is the lower-setup-cost path when serena is already wired into the session for other work.

**(b) An official single-language LSP plugin**, one per language, from the first-party plugin
marketplace. The naming pattern is `<language>-lsp`; check the marketplace listing for the exact
plugin name rather than assuming one. Under the hood these wire up the same kind of language
server serena would use — `gopls` for Go, `rust-analyzer` for Rust, `jdtls` for Java are the
obvious examples, and the same pattern (an LSP wired natively into the toolset, no MCP
round-trip) extends to whatever server exists for the target language.

Both paths land on the same underlying mechanism class (Semantic) and the same blind spots — pick
whichever costs less setup for the session at hand.

## Minimal `.serena/project.yml`

```yaml
languages:
  - go          # or: rust, java, csharp, ruby, php, lua, ...
ignore_all_files_in_gitignore: true
ignored_paths:
  - "vendor/"
  - "node_modules/"
  - "dist/"
  - "build/"
  - "target/"
```

`ignored_paths` should cover build outputs and vendored/third-party dependency trees for the
language in question — an unindexed vendor directory that gets indexed anyway both slows the
index and pollutes "find references" results with vendored copies.

## The routing table and trust calibration apply unchanged

Mechanism classes are language-independent — see `tools-catalog.md`. A Go project still has the
same three fallible classes: semantic (serena/gopls), name-match (code-review-graph, graphify),
textual (grep, ast-grep). What you lose without a bundled `code-intel-lsp` server for this
language is nothing structural — just the convenience of the tool existing natively in the
toolset with no MCP round-trip. Route through serena instead; the capability is the same.

## What every language needs before a semantic answer is trustworthy

A checklist to run once per new language, adapted to that language's tooling:

1. **The server can find the project's dependency/build metadata.** `go.mod` for Go, `Cargo.toml`
   for Rust, `pom.xml`/`build.gradle` for JVM, `.csproj`/`.sln` for .NET, `Gemfile` for Ruby,
   `composer.json` for PHP. A server pointed at a directory with no recognizable manifest indexes
   nothing and reports it as "no references" rather than "no index."
2. **An index or build has actually happened, where the language requires one.** Some servers
   (gopls, rust-analyzer) index lazily on first query; others (jdtls) want an explicit build step
   first. Check the server's own startup log, not just "it returned an empty list" — empty is the
   same output whether nothing matched or nothing was indexed (see `tools-catalog.md`'s
   silent-under-report warning).
3. **A known-answer query on a hand-counted symbol returns the right count.** Pick a symbol with
   references you can count by eye (grep it, count occurrences that are real usages), then ask
   the semantic tool for the same count. Mismatch means the index is stale or partial — find out
   which before trusting anything else it says.
4. **The completeness cross-check pattern for "all implementors" is written down for this
   language**, because it differs per language and a generic "find implementations" call can miss
   the language-specific idiom:
   - Go: embedded interfaces — a type can satisfy an interface with no explicit `implements`
     keyword at all; grep for the interface's method set, not for a keyword.
   - Rust: `impl <Trait> for <Type>` blocks — grep-able, but generic impls (`impl<T> Trait for
     Vec<T>`) can make a concrete type's conformance non-obvious from text alone.
   - Java/C#: `implements`/`extends` keywords — mostly grep-able, but reflection-based frameworks
     (DI containers, ORMs) can register implementors with no keyword in sight.
   - PHP/Ruby: dynamic/duck typing means "implements" is often a convention, not a declaration —
     lean harder on the semantic tool here, and cross-check with a runtime trace if one exists,
     not with grep.

## Adding a new stack to this plugin

To add a `setup-<stack>.md` for a language this plugin doesn't yet cover, write it to the same
six-section shape used by the language-specific guides:

1. **What "configured" means** for this language — which files/state indicate the server is
   wired up correctly.
2. **Install** — the server binary, with a `scripts/check-package.sh`-style staleness check
   before recommending a version.
3. **Per-project setup** — the equivalent of `.serena/project.yml` or the plugin's own config,
   plus what build/index step (if any) the language requires before queries are trustworthy.
4. **Known-answer gate** — a concrete example of item 3 in the checklist above, specific to this
   language's ecosystem.
5. **Traps** — anything this language's tooling gets silently wrong (a stale lockfile, a
   multi-module monorepo the server doesn't auto-discover, a build tool that needs an explicit
   sync command before the server sees new files).
6. **Blind spots** — the language-specific version of item 4 in the checklist above: what
   "implements/references/calls" idiom this language has that a generic semantic tool call won't
   surface on its own.

Cross-link with relative filenames only — `tools-catalog.md`, `mcp-wiring.md`,
`setup-python.md`, etc. — never an absolute path, since this plugin is distributed to other
machines.
