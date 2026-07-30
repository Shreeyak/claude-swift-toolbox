---
name: ferry
description: Use this skill whenever working with a physical iPad/iPhone — deploying or launching an app on device, reading/tailing/grepping device logs, pulling a scan/diagnostic run off the device, opening a live rerun view of a run, checking why a device build won't install, copying files to/from the app container, or picking between connected iPads. Trigger phrases include "deploy to the iPad", "get device logs", "what does the iPad say", "install on device", "is the iPad locked", "pull the recording off the device", "show the run in rerun". The `ferry` CLI is the canonical path for ALL of this — do not hand-roll xcrun devicectl / xcodebuild pipelines, and never use `log collect`, `log stream --device`, `idevicesyslog`, `pymobiledevice3`, or `devicectl … --console` (all broken on iOS 26.4).
---

# ferry — physical-device CLI

`ferry` wraps every working physical-iPad path on this machine: deploy,
signing recovery, device selection, lock detection, log capture, run
retrieval, file transfer. `ferry --help` is a complete usage guide (workflows,
config layers, exit codes, doc paths) — read it when unsure. Not on PATH? Ask
where the ferry repo is, then `uv tool install --editable <ferry-repo>/ferry-cli`
(the subdirectory is required — that repo's root holds the LogBrook Swift
package). From git: `uv tool install
"git+ssh://git@github.com/Shreeyak/ferry#subdirectory=ferry-cli"` — the repo is
private, so this needs an SSH key with access.

Per-project config is `.ferry.toml` at the repo root (`ferry init`
auto-detects and writes it; `ferry init --global` scaffolds per-user signing
config). Missing keys fail with `config_missing_key` naming the key.

## What to run

| You want | Run |
|---|---|
| Deploy + watch this session's logs | `ferry run --for 30s` (agent) / `--await 'PATTERN' --timeout 60` |
| Just deploy / build / test | `ferry deploy` (`--release --no-launch --clean`) · `ferry build` · `ferry test --filter Suite/Case` |
| One-shot device log snapshot | `ferry logs capture pull --session last`, then Read the printed path |
| Keep logs flowing in background | `ferry logs start` → Read/Grep the mirror (`ferry status` prints it) → `ferry logs stop` |
| Wait for a log line | `ferry logs await 'PATTERN' --timeout 60` (exit 0 seen / 5 timeout) |
| Search / list launches | `ferry logs grep 'expr' [--session last]` · `ferry logs sessions` |
| List structured runs on device | `ferry logs runs [--json]` |
| Pull a whole run (events, prose, reject PNGs) | `ferry logs pull [--latest\|--today\|<day>/<time>] [--out DIR]` |
| Follow the current run's events live | `ferry logs live [--save FILE]` |
| Open the live rerun view | `ferry logs viewer` (see rerun below) |
| Mac-app unified logs | `ferry maclogs --last 5m [--category C --level debug]` |
| Which iPads / pin one | `ferry devices [--all]` · `ferry use <name-or-udid>` · `ferry use --auto` |
| Signing identity for this project | `ferry team` (show) · `ferry team <alias>` (pin) · `ferry team --list` |
| Where does a setting come from | `ferry config` |
| Fast context / health | `ferry status --json` · `ferry doctor` |
| Files off/onto the device | `ferry cp device:/Documents/x ./x` (exactly one side has `device:`) |

## Device logs come in two transports — pick deliberately

- **`logs capture …`** (`start/stop/tail/grep/pull/sessions/await`) — polls
  the app's **file sink** via devicectl every 4 s into a local mirror. Works
  whether or not the app is running. Needs the app to enable its sink at
  startup (e.g. `CameraKitLog.enableFileLogging()`) writing `log_file` from
  `.ferry.toml`; empty pulls = that call is missing. The mirror appends
  across launches, so almost always add `--session last`; a session with no
  lines after its marker means the app crashed before logging.
- **`logs runs|pull|live|viewer`** — LogBrook: a read-only HTTP server the
  app hosts (port 7799, debug builds, Bonjour `_logbrook._tcp`). Structured
  runs, reject images, live NDJSON. Only while the app is foregrounded; if
  nothing answers, fall back to `logs capture pull`. These take
  `--host`/`--port` (not `--device`); pass `--host` to skip discovery.
- **Name trap:** `ferry logs pull` = LogBrook run mirror.
  `ferry logs capture pull` = legacy single-file devicectl pull. Every other
  bare mode (`logs tail` etc.) still aliases to `logs capture`.

## rerun (live visualization)

The device serves **no** rerun endpoint — that design was rejected. `ferry
logs viewer` discovers the device, then runs the **project's** Mac-side
bridge, which tails LogBrook `/live`, maps events through the rerun SDK, and
spawns the viewer locally: `uv run <rerun_bridge> --host H --port P`. The
bridge path is `.ferry.toml`'s `rerun_bridge`, default
`scripts/rerun-bridge.py`. No bridge in the project → `config_missing_key`;
use `ferry logs live` for raw events instead. Never point a rerun viewer at
the device yourself.

## Rules for agents

- **Exit codes are the API**: 0 ok, 1 failed, 2 usage, 3 no usable device (or
  LogBrook unreachable), 4 device LOCKED, 5 await timeout. Prefer `--json`:
  `{ok, data|error{code,evidence}, hints, artifacts}`. **Exit 4 = stop and ask
  the human to unlock** — no CLI can unlock a passcode-protected iPad, and
  ferry checks in ~1 s before building. Never retry it.
- **Long builds: launch with `run_in_background`.** xcodebuild exceeds the
  foreground timeout; the completion notification is your signal. Meanwhile
  Read the build-log path ferry prints. `logs await` is the poll-free wait.
- **Named failures are final** — free-profile 3-app limit, "maximum App ID
  limit", locked device. Don't retry, don't re-diagnose.
- **Prefer bounded forms** (`--for`, `--await`, `--last`, `logs grep`).
  Without a TTY, bare `ferry run` / `maclogs --stream` refuse with exit 2 and
  `logs tail` returns after recent lines. `logs live` streams forever by
  design — use `--save` and background it.
- **Never poll devicectl yourself**; `logs start` is already non-blocking and
  the 4 s floor exists because devicectl rate-limits.
- **One device at a time.** A pinned-but-unreachable device is exit 3, never a
  silent switch — surface it rather than retrying.
- **No simulators.** `build`/`test` fall back to Mac "Designed for iPad";
  `deploy`/`run` are physical-only.
- **Signing is the user's policy — discover, never assume**: `ferry team`
  (effective team + source), `ferry team --list` (selectable identities).
  `signing_blacklisted` and `signing_wrong_account` are deliberate refusals:
  surface them, never work around (no manual xcodebuild, no editing the
  blacklist, no touching the keychain). "No Account for Team" self-corrects.
  A `signed by "…" — NOT the configured account` warning also goes to the
  human.

## Why the do-not-use list exists (iOS 26.4)

WiFi unified-log access is broken: `log collect` fails ("Device not
configured"), `log stream --device` doesn't exist, `devicectl --console` is
USB-only and kills the app over WiFi, `pymobiledevice3` and `idevicesyslog`
are dead on modern iOS. The in-app file sink pulled via `devicectl device
copy from` (what `ferry logs capture` does) is the only working route —
suggesting the broken tools wastes the session.
