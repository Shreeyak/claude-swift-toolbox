# claude-swift-toolbox

Development tooling for Claude Code: Swift/iOS workflows, git branch topology,
and language-agnostic code intelligence.

## Install

```bash
claude plugin marketplace add Shreeyak/claude-swift-toolbox
claude plugin install swift-cxx-interop@claude-swift-toolbox
```

macOS and Linux. All scripts are bash; Windows is untested and unsupported.

## Plugins

### `code-intel`

Routes code-navigation questions to the right tool, and makes every answer name
its mechanism class. Full detail in [`plugins/code-intel/README.md`](plugins/code-intel/README.md).

- Router skill triggering on explicit navigation intent only (find callers,
  references, definitions, implementations, rename, concept search)
- Trust calibration across three fallible mechanism classes — semantic
  (LSP/serena), name-match (tree-sitter graphs), textual (grep/ast-grep)
- Deep setup guides for TypeScript, Python, C++, Swift and mixed-language
  boundaries; a generic path for every other stack
- Three fail-open bash hooks: dynamic session status (SessionStart), a
  pre-decision intent router (UserPromptSubmit), and a corrective grep nudge
  (PostToolUse — never auto-approves a tool call)
- `/code-intel:setup` (propose-then-apply, never installs binaries) and
  `/code-intel:doctor` (binary → started → initialized → workspace → probe)

```bash
claude plugin install code-intel@claude-swift-toolbox
```

### `code-intel-lsp`

`typescript-language-server`, `basedpyright`, `clangd`, `sourcekit-lsp` and the
Dart SDK's own `dart language-server` in one togglable `lspServers` map instead
of four singleton plugins — so navigation is one toggle, not four. Dart is the
fifth entry and has no upstream singleton plugin to consolidate; it is there
because nothing else ships it. Diagnostics off; activation measured lazy;
upstream provenance, the extension-conflict rule, and the Dart entry's own
caveats are documented in
[`plugins/code-intel-lsp/README.md`](plugins/code-intel-lsp/README.md).

```bash
claude plugin install code-intel-lsp@claude-swift-toolbox
```

### `ferry`

Physical iPad/iPhone workflows via the `ferry` CLI (a private companion
tool; install from its repo with `uv tool install --editable <ferry-repo>`
— must be on PATH). All policy (signing teams, blacklist, device pins) is
per-user configuration read by the CLI itself. Teaches agents:

- Deploy / run / log-capture decision tree (`ferry run --for 30s`,
  `ferry logs await 'PATTERN'`, `ferry logs pull --session last`)
- Exit-code branching (3 = no device, 4 = locked → ask the human, 5 = await
  timeout) and the `--json` envelope
- iOS 26.4 log constraints — the do-not-use list (`log collect`,
  `pymobiledevice3`, `idevicesyslog`, `devicectl --console`)
- Long-task guidance: background deploys, named deterministic failures
  (free-profile app limit), sticky device selection (`ferry use`)

```bash
claude plugin install ferry@claude-swift-toolbox
```

### `dryad`

Git branch topology via the `dryad` CLI (a companion tool; install from
its repo, must be on PATH). Teaches agents:

- Command decision table: parent-branch inference (`dryad parent`), the
  branch forest with worktree locations (`dryad tree`), a safe
  parents-before-children merge order (`dryad merge-order --onto main`),
  and the graph GUI (`dryad gui`)
- Trust the CLI's parent-branch heuristic (closest fork wins,
  cycle-guarded) instead of re-deriving it with raw `git merge-base` /
  `--fork-point`
- The `--json` (explicit nulls) and exit-code (0 ok, 1 unknown branch)
  contract, and that output has no ANSI when piped

```bash
claude plugin install dryad@claude-swift-toolbox
```

### `swift-cxx-interop`

Swift 6 / C++ interoperability reference. Covers:

- Enabling C++ interop in Package.swift and Xcode
- What can and cannot cross the boundary (no templates, lambdas, operator overloads)
- Type mapping: `std::string`, `std::span`, `std::optional`, `cv::Mat`, containers
- `SWIFT_SHARED_REFERENCE` with correct intrusive-refcount retain/release pattern
- `SWIFT_IMMORTAL_REFERENCE`, `SWIFT_UNSAFE_REFERENCE`
- `SWIFT_RETURNS_RETAINED` / `SWIFT_RETURNS_UNRETAINED` on factory functions
- Lifetime annotations: `__lifetimebound`, `SWIFT_NONESCAPABLE`, `SWIFT_SELF_CONTAINED`
- `std::span` safe interop via `-enable-experimental-feature SafeInteropWrappers`
- Customization macros: `SWIFT_COMPUTED_PROPERTY`, `SWIFT_NAME`, `SWIFT_SELF_CONTAINED`
- Swift-to-C++ export (generated header)
- Threading constraints — `cv::Mat*` across `await`
- Common errors and rationalization table

## Contributing

New skills and scripts welcome. Each skill lives in `skills/<name>/` with a `SKILL.md` and optional `scripts/` subdirectory. Run `claude plugin validate .` before opening a PR.
