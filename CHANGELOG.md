# Changelog

## 1.1.0 — 2026-08-05

### Added
- `code-intel` plugin: a router skill that routes code-navigation questions by
  question rather than by language, and that makes every answer name its
  mechanism class (semantic / name-match / textual) and that class's blind spots.
  Ships eight on-demand references (tools catalog with data boundaries and
  install lines; setup guides for TypeScript, Python, C++, Swift, mixed-language
  boundaries, and any other stack; `.mcp.json` wiring patterns), three
  behaviour-shaping hooks (SessionStart dynamic status, UserPromptSubmit intent
  router, PostToolUse grep nudge — all pure bash and fail-open; the nudge is
  PostToolUse because PreToolUse carries no `additionalContext` and its "allow"
  decision would bypass the permission system),
  `/code-intel:setup` (propose-then-apply, atomic writes, refuses malformed
  config, never installs binaries) and `/code-intel:doctor` (state model from
  binary present through known-answer semantic probe).
- `code-intel-lsp` plugin: `typescript-language-server`, `basedpyright`,
  `clangd` and `sourcekit-lsp` in one togglable `lspServers` map, all with
  `diagnostics: false`. Entries derive from the official single-language LSP
  plugins with provenance and overrides documented in its README. Activation
  measured lazy (2026-08-05): servers start on the first LSP tool call, not at
  plugin load.

### Changed
- Marketplace description broadened beyond Swift/iOS to development tooling
  generally.

## 1.0.0 — 2026-05-31

### Added
- `swift-cxx-interop` skill: Swift 6 / C++ interoperability reference covering setup, type mapping, SWIFT_SHARED_REFERENCE, lifetime annotations, std::span safe interop, customization macros, and Swift-to-C++ export
