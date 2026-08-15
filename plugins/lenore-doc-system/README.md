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

Codex users: copy `prompts/codex-lenore-doc-system.md` to
`~/.codex/prompts/` for an equivalent setup flow.

See the `doc-system` skill (`skills/doc-system/SKILL.md`) for the full
agent-facing rules — layout, per-doc-class conventions, journal shape,
enforcement table, and the settled-decisions list.
