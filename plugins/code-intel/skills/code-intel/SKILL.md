---
name: code-intel
description: Route a code-navigation or code-search question to the right tool. Use when asked to find callers of a symbol, who calls X, references or usages of X, where X is defined, all implementations/subclasses/conformers of an interface, rename a symbol across a repo, find code by meaning or concept, or search the codebase for something. Names the mechanism class of each answer (semantic, name-match, textual) and its blind spots.
---

# Code intelligence — route by question, not by language

Pick the tool that matches the *question*. Then name the mechanism class of the answer
you got (below), because each class fails differently.

## Route by question

| Question | Tool |
|---|---|
| Exact callers / references / usages of a symbol | **LSP** (native goto-references) or **serena** `find_referencing_symbols` |
| Where is X defined | **LSP** goto-definition / serena `find_symbol` |
| All implementations / subclasses / conformers | LSP or serena `find_implementations`, **plus** a textual cross-check (per-language pattern — see your setup guide) |
| Rename a symbol repo-wide | serena `rename_symbol` / LSP rename. Never a textual find-replace |
| Symbol overview of a file before editing it | serena `get_symbols_overview` |
| Find code by meaning / concept ("where do we retry uploads") | a semantic-search graph (e.g. code-review-graph `semantic_search`) |
| Review a diff / what a branch touched | code-review-graph `detect-changes` |
| Search docs and prose, connect prior work | graphify — the only tool **in this toolset** that indexes `docs/`. Lexical label-match + graph traversal, NOT embedding search — concept queries belong in the row above |
| Config constants, env vars, build flags, star-imported values | **grep / rg** — no graph or LSP resolves these |
| Structural code pattern across a repo ("every `await` inside a loop") | **ast-grep** — syntax-aware structural matching, language-agnostic |
| Known security / correctness anti-pattern | **semgrep** — structural plus, rule-dependent, dataflow/taint |
| Dead code, unused symbols | the language's own tool (`vulture` for Python, `ts-prune`/`knip` for TS, `-Wunused` builds for C++) |
| Type errors / lint | the project's own pinned tools, never a global install |

**grep keeps real lanes and they are wide**: constants, flags, string literals, prose,
filename and inventory sweeps, generated artifacts, macros and `#ifdef`'d code, anything
outside the build graph — and *completeness cross-checks of any graph or LSP answer*.
Using grep for those is correct. Using it for "who calls this function" is not.

## Trust calibration — three mechanism classes, all three fallible

**Semantic (LSP, serena).** Exact name resolution and type-aware navigation *within an
indexed build graph*. Blind spots: a partial or stale index silently **under-reports** —
you get a confident empty answer, not an error. Reflection, DI containers, code
generation, template instantiation, conditional compilation, and runtime-dispatched
selectors are invisible or approximate. "The LSP said 0 references" is evidence, not
proof; cross-check textually before deleting anything.

**Name-match (tree-sitter graphs: code-review-graph, graphify).** No build required, so
they work on a repo that will not compile. They match calls **by name**: they miss
renamed, mangled, or aliased symbols and cannot disambiguate same-named overloads by
type. Fine when names are stable and unique; a graph's "0 callers / low risk" on a
config constant or a renamed interop symbol is a likely false negative.

**Textual (grep, ast-grep).** Complete over the text it scans, and that is its whole
strength. No name resolution: it over-matches comments, strings, and unrelated symbols
that share a name.

**The rule:** any answer that feeds a refactor states its mechanism class. A semantic
answer gets a textual completeness cross-check. A textual answer gets semantic
disambiguation when the symbol name is common.

Before trusting a semantic answer for the first time in a repo, run one **known-answer
query** — a symbol whose references you counted by hand. A fresh checkout with no index
returns empty for everything, and empty looks exactly like "no callers".

## When the routed tool is not available

Say so, name the one-line fix, and proceed with the next-best mechanism **while labelling
the downgrade**. Do not silently substitute grep for a semantic question and present the
result as if it were a references list.

- Nothing configured yet → `/code-intel:setup`
- Configured but answering wrongly or not at all → `/code-intel:doctor`

## References

Load only the one you need.

- `references/tools-catalog.md` — per tool: mechanism class, winning lane, blind spots,
  data boundary, tested version, install one-liner
- `references/setup-typescript.md`, `setup-python.md`, `setup-cpp.md`, `setup-swift.md`
- `references/setup-mixed-language.md` — evidence-gathering workflow for boundary crossing
- `references/setup-generic.md` — any other language
- `references/mcp-wiring.md` — `.mcp.json` patterns and the failure modes they avoid
