# Lenore doc system — Codex setup prompt

Copy this file to `~/.codex/prompts/lenore-doc-system.md` (or paste it directly
into a Codex session) to install or align with the same documentation
system Claude Code uses via the `lenore-doc-system` plugin.

---

Read the doc system doctrine before doing anything:

- Skill (agent-facing summary): https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/skills/doc-system/SKILL.md
- Tier 1 CLAUDE.md rules block: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/skills/doc-system/references/rules-tier1.md
- Tier 0 CLAUDE.md rules block: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/skills/doc-system/references/rules-tier0.md
- Full doctrine (rationale, human-readable): https://claude.ai/code/artifact/fe938177-22fc-43d6-be6d-842ece97226b

Templates to fetch and install:

- Pre-commit hook: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/templates/githooks/pre-commit
- Pre-push hook: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/templates/githooks/pre-push
- browse.py: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/templates/scripts/browse.py
- doc-status.sh: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/templates/scripts/doc-status.sh
- docs/CLAUDE.md formatting details: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/templates/docs-CLAUDE.md
- .gitignore snippet: https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/main/plugins/lenore-doc-system/templates/gitignore-snippet

Perform the same setup Claude Code's `/lenore-doc-system:setup` command runs:

1. Detect whether this repo already has `docs-system:` in its `CLAUDE.md`.
   If so, treat this as an upgrade — diff the repo's copies of the hooks
   and scripts against the templates above and propose replacing any that
   differ. If not, this is a fresh install.
2. Ask which tier: Tier 1 (full layout — journal/notes/reference/tasks/
   bugs, openspec, experiments, desk) or Tier 0 (small repo — `docs/log/`
   only). Default to Tier 1 unless this is clearly a small/experiment repo.
3. For Tier 1: create `docs/{journal,notes,reference,tasks,bugs}/` and
   `tmp/`; fetch the two hook templates into `.githooks/` and make them
   executable; fetch `browse.py` and `doc-status.sh` into `scripts/`
   (executable); fetch `docs-CLAUDE.md` into `docs/CLAUDE.md`; run
   `git config core.hooksPath .githooks`; symlink `AGENTS.md -> CLAUDE.md`
   at repo root and beside `docs/CLAUDE.md`; append the Tier 1 rules block
   verbatim to the repo's `CLAUDE.md` followed by `docs-system: lenore-v1 (tier
   1)`; append the gitignore snippet to `.gitignore`; register
   `scripts/doc-status.sh` to run at session start in whatever mechanism
   this Codex setup uses (equivalent to Claude Code's SessionStart hook).
   For Tier 0: create `docs/log/` and append the Tier 0 rules block only.
4. **Propose before applying** — show every file to be created or
   modified, and the diff for `CLAUDE.md`/`.gitignore`, then apply only
   after the user confirms.
5. If legacy tracking docs exist (`decisions.md`, `state.md`,
   `pending.md`, `TASKS.md`, etc.), propose the migration steps described
   in the doctrine's §11 as separate confirmable diffs — do not delete
   anything until its replacement is written and confirmed.

Never invent policy beyond what's in the linked doctrine. When in doubt,
fetch and re-read the SKILL.md link above rather than guessing.
