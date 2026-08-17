# lenore-doc-system

Documentation-as-history for AI-maintained repos: dated, immutable files;
current truth kept separate from history; every high-damage rule enforced
by committed git hooks instead of prose discipline; a desk for human
retrieval; a gated landing flow for long-lived branches.

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
- `/lenore-doc-system:doc-cleanup` — doc-hygiene pass: Someday prunes,
  stale branch-task disposal, stale-bug triage, optional catch-up entry —
  all as diffs the user confirms.

## Tooling installed into each repo

- `scripts/lenore-docs.py` — CLI for creating notes/bugs/journal/tasks:
  dated filenames, shape caps with explanatory errors, `--supersedes`,
  atomic task+backing-note+pointer (`task --note`). Body via heredoc.
- `scripts/browse.py` / `scripts/doc-status.sh` — live index and the
  one-line status (journal age, stale tasks, bugs, desk, semantic-index
  staleness, dangling pointers); status runs on every SessionStart event
  including compaction.
- `scripts/docs-search.py` — local semantic search (Apple Silicon MLX),
  optional.
- `.githooks/{pre-commit,commit-msg,pre-merge-commit,pre-push}` — the
  enforcement layer: immutability, deny-filenames, prose-only docs/,
  shape of new entries, bug-fix-claim consistency, landing gate.
- Plugin-level drift lint (`hooks/hooks.json` → `doc-lint.sh`): one
  batched Haiku judgment check per docs-touching `git commit`; blocks
  once with reasons, unchanged retry proceeds. `LENORE_NO_LINT=1`
  disables.

Codex users: copy `prompts/codex-lenore-doc-system.md` to
`~/.codex/prompts/` for an equivalent setup flow.

See the `doc-system` skill (`skills/doc-system/SKILL.md`) for the full
agent-facing rules — layout, per-doc-class conventions, journal shape,
enforcement table, and the settled-decisions list.
