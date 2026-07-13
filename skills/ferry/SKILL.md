---
name: ferry
description: Use this skill whenever working with a physical iPad/iPhone — deploying or launching an app on device, reading/tailing/grepping device logs, checking why a device build won't install, copying files to/from the app container, or picking between connected iPads. Trigger phrases include "deploy to the iPad", "get device logs", "what does the iPad say", "install on device", "is the iPad locked", "pull the recording off the device". The `ferry` CLI is the canonical path for ALL of this — do not hand-roll xcrun devicectl / xcodebuild pipelines, and never use `log collect`, `log stream --device`, `idevicesyslog`, `pymobiledevice3`, or `devicectl … --console` (all broken on iOS 26.4).
---

# ferry — physical-device CLI

`ferry` wraps every working physical-iPad path on this machine: deploy,
signing recovery, device selection, lock detection, log capture, file
transfer. Check availability with `ferry --help`; install with
`uv tool install --editable ~/work/cli-tools-clara/ferry`.

Projects configure it with `.ferry.toml` at the repo root (project/workspace,
scheme, bundle_id, log_file). Missing keys produce a `config_missing_key`
error naming the key.

## Command decision tree

| You want | Run |
|---|---|
| Deploy code and watch what it logs | `ferry run --for 30s` (agent) / `ferry run` (stream) |
| Deploy and verify a specific line appears | `ferry run --await 'PATTERN' --timeout 60` |
| Just deploy | `ferry deploy` (`--release`, `--no-launch`, `--clean`) |
| Compile check / run tests | `ferry build` / `ferry test --filter Suite/Case` |
| One-shot log snapshot | `ferry logs pull --session last` then Read the printed path |
| Live log monitoring | `ferry logs start` then Read/Grep the mirror; `ferry logs stop` |
| Wait for a log line (no deploy) | `ferry logs await 'PATTERN' --timeout 60` |
| Search captured logs | `ferry logs grep 'expr' [--session last]` |
| List app launches in the log | `ferry logs sessions` |
| Which iPads are visible? | `ferry devices` (`--all` for iPhones) |
| Pin a device for the whole session | `ferry use <name-or-udid>`; `ferry use --auto` to unpin |
| Which Apple ID / team signs this project? | `ferry team` (show), `ferry team <alias>` (pin per-project), `ferry team --list` |
| Fast context (device/poller/app/last deploy) | `ferry status --json` |
| Anything misbehaving | `ferry doctor` |
| File off/onto the device | `ferry cp device:/Documents/x ./x` (one side has `device:`) |
| Mac-app unified logs | `ferry maclogs --last 5m [--category C --level debug]` |

## Rules for agents

- **Exit codes are the API**: 0 ok, 1 failed, 2 usage, 3 no usable device,
  4 device LOCKED (stop and ask the human to unlock — do not retry; no CLI
  can unlock a passcode-protected iPad, and ferry checks lock state in ~1 s
  BEFORE building), 5 await timeout (the app never logged the line). Prefer
  `--json`: envelope `{ok, error: {code, evidence}, hints, artifacts}` with
  stable codes.
- **Known deterministic failures are named** — trust the message over
  re-diagnosing: "free-profile app limit (3 dev apps)" means delete a
  dev-signed app from the iPad or use a paid team; "maximum App ID limit"
  means the free account minted too many app ids this week. Neither is
  transient; don't retry them.
- **Long tasks (deploy/run build for minutes): use `run_in_background`.**
  xcodebuild routinely exceeds the foreground Bash timeout. Launch
  `ferry deploy` / `ferry run --for 30s` with `run_in_background` — Claude
  Code notifies you when the command exits; that notification IS the
  completion signal (there is no other CLI→agent push channel). While it
  runs, ferry prints the build-log path in its first lines — Read that file
  for progress. `ferry logs await 'PATTERN'` is the poll-free way to wait
  for an in-app event (exit 0 = seen, 5 = timeout).
- **Streaming modes protect you automatically.** Without a TTY (i.e. any
  agent shell): bare `ferry run` and `maclogs --stream` refuse with exit 2
  and tell you which bounded flag to use; `ferry logs tail` prints the
  recent lines and returns instead of following forever. You should still
  prefer the bounded forms (`--for`, `--await`, `--last`, `logs grep`).
- **Don't background-fight the poller.** `ferry logs start` is already
  non-blocking and returns immediately; Read/Grep the mirror path shown by
  `ferry status` instead of tailing.
- **Device logs need the app's file sink** (e.g.
  `CameraKitLog.enableFileLogging()` at startup) writing the `log_file`
  configured in `.ferry.toml`. Empty pulls → verify the init call exists.
- **The 4 s poll interval is intentional** (devicectl rate-limits). Never
  lower it; never poll `devicectl` yourself in a loop.
- **Sessions**: the device log appends across launches. Almost always you
  want `--session last`. A session with zero lines after its marker = the
  app crashed before logging.
- **One device at a time.** `ferry use` pins it; an unreachable pinned
  device is exit 3 with a hint — ferry never silently switches iPads, so
  surface that to the human instead of retrying.
- **No simulators.** They are disallowed on this machine. `ferry build`/
  `ferry test` fall back to Mac "Designed for iPad" automatically;
  `ferry deploy`/`ferry run` are physical-only by design.
- **Signing**: identities are managed — `ferry team` shows the effective
  team, `ferry team <alias>` pins one for the project (persists in
  `.env.local`), the default is Shreeyak's team, and **blacklisted teams
  (Sous Chef) are refused everywhere**, including a codesign check of the
  built app before install. A `signing_blacklisted` error is intentional
  policy — NEVER work around it (no manual xcodebuild, no editing the
  blacklist); surface it to the human. "No Account for Team" still
  self-corrects (CN parenthetical → real OU). If `signing_no_team`, ask
  the human which identity to pin.

## Why the do-not-use list exists (iOS 26.4)

WiFi unified-log access is broken: `log collect` fails ("Device not
configured"), `log stream --device` doesn't exist, `devicectl --console` is
USB-only and kills the app over WiFi, `pymobiledevice3` and
`idevicesyslog` are dead on modern iOS. The in-app file sink pulled via
`devicectl device copy from` (what `ferry logs` does) is the only working
route — suggesting the broken tools wastes the session.
