# Python setup

## What "configured" means

The LSP tools read the response of `basedpyright-langserver --stdio` (a fork of `pyright` with
stricter defaults; the official singleton plugin uses `pyright-langserver` instead — either binary
works, this plugin picks basedpyright). "Configured" means: the server can find the *project's*
interpreter/virtualenv and resolve imports through it.

The environment is the whole game. Point the server at the wrong interpreter (or none) and it
still starts, still answers, and silently under-reports or misresolves every third-party import —
a confident wrong answer, not an error. This is the Python-specific version of the general
trust-calibration rule: verify before trusting (see the gate below).

## Install

```bash
uv tool install basedpyright
```

`uv tool install` is not a self-modifying installer in the blocked sense (it doesn't rewrite this
plugin's own config), but if the environment forbids arbitrary global tool installs, ask the human
to run it instead.

If `uv` itself is missing:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

That script does modify the shell profile — ask the human to run it rather than running it
yourself.

## Environments and installs go through `uv`

Not `pip`, not `python -m venv`. This project's environment tooling:

```bash
uv venv                              # create .venv
uv pip install -r requirements.txt   # requirements-based install
uv sync                              # pyproject.toml-based install
uv add <pkg>                         # add a dependency to pyproject.toml
```

If you find a repo still on bare `pip`/`venv`, that's a legacy setup, not a reason to use `pip`
yourself — use `uv pip install` against the existing `venv` instead of migrating mid-task unless
asked.

## Per-project setup

1. Confirm a virtualenv exists (`.venv` from `uv venv`, or whatever the repo already uses) and has
   the project's dependencies installed into it.
2. Point the server at it. Either:
   - `pyrightconfig.json` at the project root:
     ```json
     { "venvPath": ".", "venv": ".venv" }
     ```
   - or `pyproject.toml`:
     ```toml
     [tool.basedpyright]
     venvPath = "."
     venv = ".venv"
     ```
   - or activate the venv (`source .venv/bin/activate`) before the server process launches, so it
     inherits the interpreter from `$PATH`. Config-file pinning is more reliable than relying on
     activation state carrying through to a spawned subprocess.
3. For **src-layout** repos (`src/<pkg>/...`) or namespace packages, confirm the import root is
   set correctly (`pyrightconfig.json`'s `"include"`, or an `__init__.py`/PEP 420 namespace
   package boundary). If the server's notion of the root is wrong, every cross-module reference
   comes back empty even though the interpreter is correct.

## Apple Silicon trap

`uv tool install` of anything that pulls in `cryptography` (serena and several other
Python-packaged code-intel tools do) needs an explicit arm64 Python pin:

```bash
uv tool install <pkg> -p cpython-3.13-macos-aarch64-none
```

A stray x86_64 uv-managed Python cross-builds `cryptography` from source and fails. A failed
`--force` re-install can leave the *previously working* tool uninstalled — recover by reinstalling
with the pin above, not by retrying `--force` again.

## Known-answer verification gate

Before trusting any find-references / goto-definition result in this session:

1. Pick a function you can independently confirm has exactly N call sites (grep it).
2. Run the LSP's find-references on that symbol.
3. If the count is short, suspect environment resolution first: check that the server's reported
   interpreter/venv (visible in `/plugin`'s Errors/Info tab, or by checking which `site-packages`
   it resolved) actually matches the project's virtualenv, not a system or unrelated Python.

Do this once per session before relying on LSP output for anything load-bearing.

## serena alternative

```yaml
languages: [python]
```

in `.serena/project.yml`. Same environment-resolution rules apply — serena drives the same
pyright-family server underneath.

## grep's mandatory lane in Python

No LSP and no tree-sitter graph resolves these — grep is not a fallback here, it's the only tool
that sees them at all:

- Star imports: `from x import *` — the name entering scope has no static origin the LSP can
  chase.
- Module-level constants and `__all__` lists.
- Anything reached via `getattr`, `importlib.import_module`, or other string-driven dynamic
  lookup.
- Entry points and plugin registration: `pyproject.toml` `[project.entry-points]`, Django app
  configs, Flask blueprints registered by string, pytest fixtures/plugins discovered by name or
  convention (`conftest.py`, `pytest11` entry points).

## What this stack's semantic tools cannot see

- Metaclasses that inject or rewrite attributes at class-creation time.
- Decorators that rewrap a function (`functools.wraps`-style or not) — the LSP shows the
  decorator's declared signature, not necessarily the effective one.
- Dynamic attribute access (`getattr`/`setattr`, `__getattr__` on modules or classes).
- Plugin/entry-point discovery (see grep's lane above) — a registered handler looks
  "unreferenced" to every tool here.
- Duck-typed call sites — no nominal type to follow, so "find implementations" undercounts.
- Monkeypatching in tests (`monkeypatch.setattr`, mock patch targets given as strings).
- C extensions — the Python-side stub is where the trail ends; the LSP cannot cross into compiled
  code. See `setup-mixed-language.md` for the C/C++ side of that boundary.

## Adjacent tools

| Tool | What it catches |
|---|---|
| `ruff` | Lint + format (replaces flake8/black) |
| `mypy` or `basedpyright` (CLI mode) | Full-project type errors, not just per-request LSP checks |
| `vulture` | Dead code — with the same entry-point/plugin false positives as `ts-prune`; give it an allowlist for those |

See also: `setup-mixed-language.md`, `tools-catalog.md`, `mcp-wiring.md`.
