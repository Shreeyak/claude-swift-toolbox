# claude-swift-toolbox

Swift and iOS development skills and scripts for Claude Code.

## Install

```bash
claude plugin marketplace add Shreeyak/claude-swift-toolbox
claude plugin install swift-cxx-interop@claude-swift-toolbox
```

## Plugins

### `ferry`

Physical iPad/iPhone workflows via the `ferry` CLI (lives in the private
`cli-tools-clara` collection; install with
`uv tool install --editable ~/work/cli-tools-clara/ferry`). Teaches agents:

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
