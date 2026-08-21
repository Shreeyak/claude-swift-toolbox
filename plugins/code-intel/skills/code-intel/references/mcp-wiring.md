# MCP wiring

`.mcp.json` patterns for the code-intelligence servers, and the failure modes each pattern avoids.
See `tools-catalog.md` for what each tool does; this document is only about getting them running.

## The one rule: point at the installed binary, never an ephemeral-runner wrapper

`uvx <pkg> serve` (and equivalents like `npx -y <pkg>`) rebuild an ephemeral environment on
**every launch**. For any package with a native dependency (`cryptography` is the recurring one
on this stack), that means re-hitting the same build failure on every session start, and the
server sits at "connecting…" with no useful error surfaced in the client UI.

Wrong — rebuilds an environment every launch, silently stuck if that build ever fails:

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["serena-agent", "serve"]
    }
  }
}
```

Right — points at a binary already installed once, on a machine where the install already
succeeded:

```json
{
  "mcpServers": {
    "serena": {
      "command": "serena",
      "args": ["start-mcp-server", "--project", "."]
    }
  }
}
```

Install once with `uv tool install` (see `tools-catalog.md` for the Apple Silicon arch-pin trap),
verify the binary resolves (`which serena`), then reference that binary directly in `.mcp.json`.

## Concrete entries (project-scoped `.mcp.json`)

```json
{
  "mcpServers": {
    "serena": {
      "command": "serena",
      "args": ["start-mcp-server", "--project", "."]
    },
    "code-review-graph": {
      "command": "code-review-graph",
      "args": ["serve"],
      "cwd": "<abs project path>"
    },
    "graphify": {
      "command": "graphify",
      "args": ["mcp", "<abs project path>/graphify-out/graph.json"]
    }
  }
}
```

Notes:

- serena takes the project root as `--project .` and additionally adopts the *server process's*
  working directory — see the cwd-binding gotcha below.
- code-review-graph is pinned to a directory via the explicit `cwd` field, not an argument.
- graphify's MCP entrypoint takes an **absolute** path to its graph file — a relative path
  resolves against whatever directory the MCP host happened to launch from, which is rarely what
  you want. Exact flag/arg names vary by release; check the installed tool's `--help` and the
  project's README before trusting the args shown here.

## The cwd-binding gotcha, and what it means for multi-worktree work

Each of these servers is bound to **one directory**: serena adopts the server process's working
directory, code-review-graph takes a pinned `cwd`, graphify takes an absolute graph-file path.
Once a server is started against directory A, every tool call through it operates on A — there is
no per-call "look at directory B instead" argument.

Consequences:

- A session started in worktree A sees only A through its MCP tools. A subagent spawned from that
  session inherits the same A-bound servers, even if the subagent's own working directory is B.
- Asking a session to "survey all worktrees" or "compare branch A and branch B" through MCP tools
  alone will silently survey A only — no error, just an answer that's wrong about B without
  saying so.

### Git worktrees need two separate things set up, not one

This applies to **every language**, not to any particular stack — the cause is serena's context
model, not anything about the code being indexed.

A `.serena/project.yml` inside a worktree is what a session whose cwd is already inside that
worktree will pick up at startup — that part works. What it does **not** do is add the worktree to
the `projects:` registry in `~/.serena/serena_config.yml`. That file's own comment on the
`projects:` key says "(updated automatically)", which sits awkwardly next to the observed
behaviour: a registry can list a main checkout opened in ordinary sessions over time while
omitting a worktree that has had its own `.serena/project.yml` across multiple sessions. What
triggers the append for one and not the other is **not confirmed** — plausibly an
`activate_project` call, a non-worktree cwd path, or something else internal to serena. Treat "not
updated for worktrees resolved by cwd" as the observed fact and the mechanism behind it as
unconfirmed.

In Claude Code's default `claude-code` context, serena is **single-project**: it resolves its
active project once, from the session's cwd, at startup, and the `activate_project` tool that
would let a running session switch projects is disabled in that context by design (confirmed by a
serena maintainer, <https://github.com/oraios/serena/issues/1109>).

Practically:

- Start each worktree's session with cwd **already inside that worktree**.
- Don't expect a session started in worktree A to see worktree B through serena, even if B has its
  own `.serena/project.yml`. There is no per-call "look at this other directory instead" argument
  — matching every other MCP server this plugin wires up, per the cwd-binding rule above.
- If something must reach a worktree from outside a session already rooted there, add its
  absolute path to the `projects:` list in `~/.serena/serena_config.yml` by hand.

Note that a linked worktree's `.git` is a **file** (`gitdir: …/.git/worktrees/<name>`), not a
directory — a plain `[ -d .git ]` test reports a worktree as a non-repository.

Fixes, in order of how much setup they cost:

1. **Use tools that take an explicit target instead of an implicit cwd.** File reads and `rg`
   against absolute paths work regardless of which directory the MCP servers are bound to. The
   graph tools' own **CLIs** (not the MCP wrapper) generally accept an explicit
   `--graph`/directory argument — use the CLI directly for cross-directory queries instead of the
   MCP tool.
2. **Register one server instance per directory**, each with its own name and an explicit
   `--project <abs path>` / `cwd` pointing at a different worktree. This works but doubles the
   approval and maintenance burden per additional directory.

## Approval

Project-scoped servers in `.mcp.json` start as **pending approval** and their tools do not exist
in the session's toolset until approved in-session. If a server "isn't showing up," check pending
approvals before debugging the process itself.

## Debugging a stuck server by hand

Run the exact `command`/`args` pair from `.mcp.json` directly and pipe a JSON-RPC `initialize`
request into it:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"debug","version":"0"}}}' | serena start-mcp-server --project .
```

A stack trace or Python/Node traceback tells you what actually broke (usually a missing
dependency or a bad path argument). A JSON `result` containing `serverInfo` means the server is
healthy and the problem is client-side (approval, `.mcp.json` syntax, wrong `cwd`).

`timeout(1)` is **not installed on macOS by default** — don't rely on it to bound a hung process.
Wrap manually instead:

```bash
serena start-mcp-server --project . & pid=$!
sleep 5
kill "$pid" 2>/dev/null
```

## Scope and secrets

`.mcp.json` is typically committed and shared across a team. Absolute paths inside it are
per-machine and will break for a teammate on a different filesystem layout — prefer relative
paths (resolved from the repo root) or environment-variable-driven values over hardcoded absolute
paths where the tool supports it. Never put a token or API key directly in `.mcp.json`; use an
env-var reference and keep the actual value in the shell environment or a gitignored `.env`.

## Where the LSP alternative wins

The `code-intel-lsp` companion plugin declares language servers natively — their navigation
tools appear in the ordinary toolset with **no MCP wiring, no approval step, and no cwd
binding**. Prefer it for plain navigation (go-to-definition, find-references, diagnostics). Reach
for an MCP server only for what it adds *beyond* navigation: serena's symbol-level edits,
code-review-graph's concept search, graphify's prose/docs graph.
