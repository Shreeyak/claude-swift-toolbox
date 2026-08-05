# TypeScript / JavaScript setup

## What "configured" means

The LSP tools read the response of `typescript-language-server --stdio`, which itself wraps
`tsserver` (the TypeScript compiler's language-service API). "Configured" means: the server can
find a `typescript` package to load, and the file you're querying is inside a project the server
has loaded via `tsconfig.json`.

When either is missing, the server does not error to the tool caller — it answers "0 references"
or "no definition found". A confident empty answer, not an error, is the default failure mode.
Never read an empty result as ground truth without first confirming the server is actually up
(see the verification gate below).

## Install

```bash
npm i -g typescript-language-server typescript
```

Or per-project (preferred — see the version trap below):

```bash
npm i -D typescript-language-server typescript
```

`typescript-language-server` is not a self-modifying installer, so this is safe to run directly.
If the repo has no package manager set up yet, or install requires elevated/global write access,
ask the human to run it instead of doing it yourself.

## Per-project setup

1. Confirm a `tsconfig.json` exists at (or above) the files you'll query. If not, `tsc --init` is
   enough to get a server to start, though references will under-resolve until `include`/`paths`
   are real.
2. Confirm `typescript` resolves from the workspace: `node -e "console.log(require.resolve('typescript/package.json'))"` run from the project root.
3. For a monorepo with project references, run the build once so declaration output exists:
   ```bash
   npx tsc -b
   ```
   Cross-package find-references needs the `.d.ts` output of referenced projects on disk — a
   fresh checkout with no build has nothing to resolve against.

## THE critical trap (measured)

`typescript-language-server` needs a loadable `typescript` library — either in the workspace's
`node_modules` or a global install. A bare repo with no `typescript` dependency fails at
`initialize`, before any tool call.

**Pin `typescript@^5` in the workspace.** `typescript@7`, the Go-native rewrite, does not ship
`lib/tsserver.js`, so `typescript-language-server` cannot load it. Until the language server adds
support for 7, a workspace on `typescript@7` will spawn the server and then fail on the first
request.

Measured 2026-08-05 with `typescript-language-server` against `typescript` 5.9 (works) and
`typescript` 7 (fails).

The symptom is misleading: the server *spawns* on the first LSP tool call, so nothing looks wrong
up front. The failure shows up in `/plugin`'s Errors tab, not in the tool result — a tool call
made while the server is dead just returns an empty or generic-failure result. If find-references
or goto-definition looks suspiciously empty, check `/plugin` before trusting the emptiness.

## Path aliases

`paths` entries in `tsconfig.json` (e.g. `"@app/*": ["src/app/*"]`) resolve correctly for the LSP,
because tsserver resolves them the same way the compiler does. They do **not** resolve for grep or
for a tree-sitter/name-match graph (code-review-graph, graphify) — those tools see the literal
import string, not the resolved path, and will miss or misattribute an aliased import. Route
alias-crossing lookups through the LSP, not grep.

## Known-answer verification gate

Before trusting any find-references / goto-definition result in this session:

1. Pick an exported function or type you can independently confirm has exactly N call sites
   (grep it, or recall from prior investigation).
2. Run the LSP's find-references on that symbol.
3. Compare counts. If the LSP returns a different number, check `/plugin` Errors before
   proceeding — the server may not be initialized, or `typescript` failed to load (see the trap
   above).

Do this once per session before relying on LSP output for anything load-bearing.

## serena alternative

If serena is available instead of (or alongside) the native LSP tools, point it at the project
with a `.serena/project.yml`:

```yaml
languages: [typescript]
```

serena wraps the same `typescript-language-server`/tsserver stack, so the install and the version
trap above apply identically.

## What this stack's semantic tools cannot see

- Dynamic `import()` with a computed specifier.
- String-keyed property access (`obj[key]`) — no static resolution.
- Call sites where the receiver is typed `any` — the type checker gives up, so does the LSP.
- Framework file-based routing (Next.js, Remix, etc.): a route file looks "unreferenced" to every
  tool here, but the framework loads it by path convention at runtime. Do not flag these as dead
  code from tool output alone.
- Decorators and DI containers that wire by string token or reflection (NestJS, InversifyJS).
- Generated API clients (OpenAPI/GraphQL codegen) — the generator, not a call site, is the real
  producer; the LSP sees only the generated file.
- JSON and CSS module imports (`import data from './x.json'`) — typed but not meaningfully
  "referenced" the way a function is.
- Monkey-patching (`Object.prototype.x = ...`, module augmentation) — the LSP shows the
  declaration site, not every effective call site.
- Re-export barrels (`export * from './impl'`) — "go to definition" from a consumer often lands on
  the barrel file, not the implementation. Follow one more hop by hand.

## Adjacent tools

| Tool | What it catches that the LSP doesn't |
|---|---|
| `tsc --noEmit` | Full-project type errors; the LSP checks per-file/per-request, not the whole graph at once |
| the project's own `eslint` (never a global install — it shadows the pinned config) | Style and correctness lint rules outside the type system |
| `knip` or `ts-prune` | Dead/unused exports across the whole project, including the file-based-routing false positives above (they have their own allowlist mechanisms) |

See also: `setup-mixed-language.md`, `tools-catalog.md`, `mcp-wiring.md`.
