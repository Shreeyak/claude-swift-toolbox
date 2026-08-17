---
name: lenore-doc-setup
description: Install, align with, or run the landing flow for the Lenore documentation-as-history system (dated immutable journal/notes/runs, git-hook enforcement, status line, filing CLI) in the current repo. Use when the user asks to set up the Lenore doc system, check a repo against it, or land a branch under it.
---

# Lenore doc system — Codex setup + landing skill

Install this skill at `~/.agents/skills/lenore-doc-setup/SKILL.md` (user
scope) or ship it in a repo at `.agents/skills/lenore-doc-setup/SKILL.md`.
It installs, aligns with, and runs the landing flow for the same
documentation system Claude Code uses via the `lenore-doc-system` plugin —
self-contained for Codex, no Claude-only mechanisms referenced.

---

## 0. Where to get the doctrine and templates

**Prefer local files first.** If the `claude-swift-toolbox` repo is present
on disk (check common locations, or ask the user where it's checked out),
read the doctrine and copy the templates directly from
`plugins/lenore-doc-system/` in that checkout — no network fetch needed.

Only if the repo is not on disk, fall back to raw GitHub URLs **pinned to a
specific commit** (not `main`, which can change under you and has no
offline/no-network fallback in Codex's default sandbox):

- Skill (agent-facing summary): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/skills/doc-system/SKILL.md`
- Tier 1 CLAUDE.md rules block: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/skills/doc-system/references/rules-tier1.md`
- Tier 0 CLAUDE.md rules block: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/skills/doc-system/references/rules-tier0.md`
- Full doctrine (rationale, human-readable): https://claude.ai/code/artifact/fe938177-22fc-43d6-be6d-842ece97226b
- Pre-commit hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/githooks/pre-commit`
- Pre-push hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/githooks/pre-push`
- Commit-msg hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/githooks/commit-msg`
- Pre-merge-commit hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/githooks/pre-merge-commit`
- browse.py: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/scripts/browse.py`
- doc-status.sh: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/scripts/doc-status.sh`
- docs-search.py: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/scripts/docs-search.py`
- lenore-docs.py: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/scripts/lenore-docs.py`
- docs/CLAUDE.md formatting details: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/docs-CLAUDE.md`
- .gitignore snippet: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/gitignore-snippet`
- doc-lint.sh (commit-time judgment lint): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/scripts/doc-lint.sh`
- doc-lint-judge.md (the lint's judge prompt): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/agents/doc-lint-judge.md`
- Codex hooks config (SessionStart status + PreToolUse lint): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/80b5b26fdb126a8243e3b515957a1d9491195843/plugins/lenore-doc-system/templates/codex-hooks.json`

When you bump the pin, re-verify each template still matches what's
described in this prompt.

## 1. Setup (same shape as Claude Code's setup flow)

1. Detect whether this repo already has `docs-system:` in its `CLAUDE.md`.
   If so, treat this as an upgrade — diff the repo's copies of the hooks
   and scripts against the templates above and propose replacing any that
   differ. If not, this is a fresh install. Either way, also run an
   **activation check**: verify `git config core.hooksPath` is
   `.githooks`, the three hook files exist and are executable, root
   `AGENTS.md -> CLAUDE.md` and `docs/AGENTS.md -> CLAUDE.md` symlinks
   exist, `docs/desk/` and `tmp/` exist (Tier 1; both are gitignored and
   so vanish on a fresh clone), and `.codex/hooks.json` registers
   `scripts/doc-status.sh` — repair anything missing, since a fresh clone
   with the marker in `CLAUDE.md` still needs this repaired locally.
2. Ask which tier: Tier 1 (full layout — journal/notes/reference/tasks/
   bugs, openspec, experiments, desk) or Tier 0 (small repo — `docs/log/`
   only). Default to Tier 1 unless this is clearly a small/experiment repo.
3. For Tier 1: create `docs/{journal,notes,reference,tasks,bugs}/`,
   `docs/desk/`, and `tmp/`; create `docs/tasks/project.md` with `## Next`
   and `## Someday` headings if absent; fetch the three hook templates
   (pre-commit, pre-push, pre-merge-commit) into `.githooks/` and make
   them executable; fetch `browse.py`, `doc-status.sh`, and
   `docs-search.py` into `scripts/` (executable); fetch `docs-CLAUDE.md`
   into `docs/CLAUDE.md`; run `git config core.hooksPath .githooks` (stop
   and ask first if it's already set to something else, or `.githooks/`
   already has other hooks — propose chaining, don't overwrite); symlink
   `AGENTS.md -> CLAUDE.md` at repo root and beside `docs/CLAUDE.md`;
   append the Tier 1 rules block verbatim to the repo's `CLAUDE.md`
   followed by `docs-system: lenore-v1 (tier 1)` (skip the append if the
   marker text is already present — idempotent re-run); append the
   gitignore snippet to `.gitignore` (skip if already present); install
   `templates/codex-hooks.json` as `.codex/hooks.json` in this repo (merge
   into any existing hooks config, never overwrite) — it registers
   `scripts/doc-status.sh` on `SessionStart` and `scripts/doc-lint.sh` as a
   `PreToolUse` hook on Bash (the commit-time judgment lint; copy
   doc-lint.sh AND doc-lint-judge.md into `scripts/`, chmod +x the .sh —
   the lint uses `codex exec` with gpt-5.6-terra at medium effort as its
   judge when `claude` isn't installed). Codex requires per-repo hooks to
   be trusted: the first interactive `codex` session prompts once and
   records a per-hook `trusted_hash` (sha256) under `[hooks.state]` in
   `~/.codex/config.toml`; until then non-interactive `codex exec` runs
   skip the hooks (`--dangerously-bypass-hook-trust` exists for CI that
   vets hook sources itself).
   For Tier 0: create `docs/log/` with a `.gitkeep` inside it (survives a
   fresh clone), symlink root `AGENTS.md -> CLAUDE.md`, and append the
   Tier 0 rules block only (idempotent, same marker check).
4. **Propose before applying** — show every file to be created or
   modified, and the diff for `CLAUDE.md`/`.gitignore`, then apply only
   after the user confirms.
5. If legacy tracking docs exist (`decisions.md`, `state.md`,
   `pending.md`, `TASKS.md`, etc.), propose the migration steps described
   in the doctrine's §11 as separate confirmable diffs — do not delete
   anything until its replacement is written and confirmed.

## 2. Landing flow (Codex-native equivalent of the doc system's `land` flow)

Codex has no slash commands, so this section *is* the landing flow — run it
directly when the user says something like "land this branch" / "merge it
in" / "wrap up this branch," the same trigger words the doctrine describes.
A landing is a merge into the default branch, or an explicit decision to
abandon the branch; both run steps 1-4 below, with the merge (or
abandonment) always last.

0. **Preconditions.** Verify the current branch is not the default branch
   (`git symbolic-ref refs/remotes/origin/HEAD`, falling back to `main`
   then `master`) — if it is, stop. The branch's task file is
   `docs/tasks/branch-<slug>.md` where `<slug>` is the branch name with
   every `/` replaced by `-`. If the default branch is checked out in a
   different worktree (`git worktree list`), you'll merge there in step 5
   — never check out the default branch in the current worktree if it's
   already checked out elsewhere.
1. **Final spec sync.** Make sure `openspec/specs/` reflects what actually
   landed, in the same commit style as the rest of the branch.
2. **Closing journal entry.** Write one
   `docs/journal/YYYY-MM-DD-HHMM-topic.md` entry (line 1 = one sentence,
   ≤10 lines/150 words, no headers/bullets, cite commit hashes) opening
   with "landing <branch>: …". This is fine to write before the merge; if
   the merge/push in step 5 then fails, append a **new** journal entry
   noting the landing did not complete — never edit the first entry
   (journal entries are immutable once committed).
3. **Archive the openspec change folder.** Run `openspec archive <name>`
   (the CLI also performs the spec update; it writes to
   `openspec/changes/archive/<date>-<name>/`). Only if the CLI is absent,
   hand-move the folder there and sync `openspec/specs/` yourself. Add a
   one-line note if the change was dropped rather than completed.
4. **Graduate branch tasks; walk the desk.** Open
   `docs/tasks/branch-<slug>.md`; for each open item, graduate it into
   `docs/tasks/project.md` (`## Next` or `## Someday`) or drop it, then
   delete the branch file. Walk `docs/desk/`: default is to unpin (`rm`
   the symlink — desk pins are gitignored, `git rm` won't touch them); if
   the user wants to keep one, add a pointer line to `project.md` first,
   then unpin.
5. **Merge — last step.** Confirm the landing markers hold (no
   `docs/tasks/branch-*.md` for this branch, no unarchived
   `openspec/changes/*/` folders other than `archive/`). Merge into the
   default branch using the repo's normal merge method, in the worktree
   where the default branch is checked out. Never bypass hooks to force
   this through — if the pre-push gate rejects the push, a marker is
   genuinely still missing; fix it and retry.

If abandoning rather than merging: skip step 5's merge but still run
steps 1-4, then leave or delete the branch per the user's instruction.

## Notes

Never invent policy beyond what's in the linked doctrine. When in doubt,
read (or fetch) the SKILL.md link above rather than guessing. The pre-push
hook only gates a `git push` that updates main/master — it does not gate a
bare local `git merge`, and it only applies once `core.hooksPath` is set in
this clone (step 1's activation check exists for exactly this reason).
