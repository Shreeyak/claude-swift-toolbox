# lenore-doc-system

Documentation-as-history for AI-maintained repos: dated, immutable files;
current truth kept separate from history in a three-file spine —
`docs/system` (how it works now, incl. the mandatory-read premises),
`docs/caveats.md` (where it fails now — named entries + Validity ladders),
`docs/playbook.md` (procedures, evaluated tools, adopted research) —
plus revisable status-carrying `docs/proposals/`; a closed, hook-enforced
docs/ layout; every high-damage rule enforced by committed git hooks
instead of prose discipline; a desk for human retrieval; a gated landing
flow for long-lived branches.

Full doctrine (rationale, design history, adversarial-review ledger):
https://claude.ai/code/artifact/fe938177-22fc-43d6-be6d-842ece97226b

## Install

```
claude plugin marketplace add Shreeyak/claude-swift-toolbox
claude plugin install lenore-doc-system@claude-swift-toolbox
```

## Commands

- `/lenore-doc-system:setup` — detect or install the doc system in the current
  repo (propose-then-apply; Tier 0 or Tier 1).
- `/lenore-doc-system:land` — run the landing flow for the current branch:
  spec sync, closing journal entry, archive the openspec change, walk
  branch tasks and the desk, merge as the last step.
- `/lenore-doc-system:desk` — review the desk: list pins with summaries
  and ages, renew-or-drop the stale ones, suggest unpinned docs.
- `/lenore-doc-system:doc-health` — launch the corpus-wide truth audit
  in the background: the `doc-health-auditor` agent (Sonnet, medium
  effort) works in its own worktree branch — stale docstrings,
  falsified spine claims, duplication drift, orphans — and reports an
  evidence-backed diff the user merges. Triggered by the status line's
  `doc-health: due` nag. Codex equivalent: `scripts/doc-health.sh &`.
- `/lenore-doc-system:doc-cleanup` — doc-hygiene pass: Someday prunes,
  stale branch-task disposal, stale-bug triage, experiment-store triage
  (delete/keep/promote run outputs, orphaned-store repair), optional
  catch-up entry — all as diffs the user confirms.

## Tooling installed into each repo

- `scripts/lenore-docs.py` — CLI for creating notes/bugs/journal/tasks/
  proposals: dated filenames, shape caps with explanatory errors,
  `--supersedes`, `--research`/`--bundle` for research notes, atomic
  task+backing-note+pointer (`task --note`) and proposal+task-pointer.
  Body via heredoc.
  Also `experiment` (dated dir + README skeleton + notebook/ + data
  symlink + store trio under the gitignored `/data/` root) and `run`
  (reserves the next runNNN id by creating its store out/ dir).
  `proposal` and `experiment` both end with a recall step — top semantic
  hits for the title/question print in the tool's own output.
- `scripts/browse.py` / `scripts/doc-status.sh` — live index and the
  one-line status (journal age, stale tasks, bugs, desk, semantic-index
  staleness, dangling pointers); the plugin's own SessionStart hook runs
  it on every event including compaction — no per-repo hook registration.
- `scripts/docs-search.py` — local semantic search (Apple Silicon MLX),
  optional.
- `.githooks/{pre-commit,commit-msg,pre-merge-commit,pre-push}` — the
  enforcement layer: immutability (journal, notes, experiment notebook
  entries), deny-filenames, the closed docs/ layout (fixed top-level
  set, per-area extension rules incl. diagram sources and note bundles,
  5MB size cap), proposal `status:` front-matter, shape of new entries
  (including notebook entries: runNNN names, a header naming its own
  file, line-1 outcome sentence, unique numeric run ids per experiment),
  the append-only PROMOTIONS.md ledger,
  the experiment conclusion gate (status flip needs verdict + date +
  journal entry in one commit), experiment isolation (no imports or
  symlinks into experiments/ from production code; intra-experiments
  reuse is fine and each experiment's data symlink is blessed only when
  it points exactly at its own store dir), a rename
  warning when an experiment dir moves without its store dir, merge
  guidance for same-named dated notes (both versions must survive; one
  gets refiled), landing gate.
- Plugin-level drift lint (`hooks/hooks.json` → `doc-lint.sh`): one
  batched Haiku judgment check per `git commit` touching docs/ entries or
  experiment notebook entries — including whether a new run contradicts
  its experiment README's standing verdict; blocks once with reasons,
  unchanged retry proceeds. `LENORE_NO_LINT=1` disables. The judgment prompt ships as a real agent,
  `agents/doc-lint-judge.md` — the lint script sources its prompt from
  that file, and the agent can also be invoked directly ("check
  docs/tasks/project.md against the doc rules"). It carries only the
  cheap pattern-level hygiene tells; three agents divide the doc work:
  `doc-lint-judge` (Haiku — commit-time, touched files),
  `landing-doc-reviewer` (Sonnet — the branch diff at landing: docs AND
  docstrings, reader-modeling duties, contradiction cross-check), and
  `doc-health-auditor` (Sonnet — corpus truth maintenance via
  /doc-health, own worktree). All three share ONE rulebook,
  `skills/doc-system/references/doc-hygiene-rules.md` (copied to
  `scripts/doc-hygiene-rules.md` by setup): no invented entry IDs,
  no session-opaque codenames, present-tense contract prose in living
  docs/docstrings, no reviewer-directed comments.
- `tests/doc-lint/` — committed regression suite for the judge (20
  cases + runner + provenance README). Run `tests/doc-lint/run-suite.sh`
  before shipping any change to the judge prompt or the lint script.

Codex users: copy `codex/skills/lenore-doc-setup/` to
`~/.agents/skills/lenore-doc-setup/` — a Codex skill (the current
mechanism; `~/.codex/prompts/` is deprecated) that drives the same
setup/landing flow. Repos set up by Claude's `/setup` are Codex-ready out
of the box: `.codex/hooks.json` registers the status line (SessionStart)
and the commit-time doc lint (PreToolUse), and the lint's judge falls back
from `claude`/Haiku to `codex exec`/gpt-5.6-terra automatically.

See the `doc-system` skill (`skills/doc-system/SKILL.md`) for the full
agent-facing rules — layout, per-doc-class conventions, journal shape,
enforcement table, and the settled-decisions list.
