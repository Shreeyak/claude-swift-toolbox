---
name: lenore-doc-setup
description: Install, align with, or run the landing flow for the Lenore documentation-as-history system (dated immutable journal/notes/notebook entries, git-hook enforcement, status line, filing CLI) in the current repo. Use when the user asks to set up the Lenore doc system, check a repo against it, or land a branch under it.
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

- Skill (agent-facing summary): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/skills/doc-system/SKILL.md`
- Tier 1 CLAUDE.md rules block: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/skills/doc-system/references/rules-tier1.md`
- Tier 0 CLAUDE.md rules block: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/skills/doc-system/references/rules-tier0.md`
- Experiment README + notebook-entry templates (incl. candidate-system): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/skills/doc-system/references/experiment-templates.md`
- Setup command (spine-stub contents + migration steps): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/commands/setup.md`
- Full doctrine (rationale, human-readable): https://claude.ai/code/artifact/fe938177-22fc-43d6-be6d-842ece97226b
- Pre-commit hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/githooks/pre-commit`
- Pre-push hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/githooks/pre-push`
- Commit-msg hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/githooks/commit-msg`
- Pre-merge-commit hook: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/githooks/pre-merge-commit`
- browse.py: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/browse.py`
- doc-status.sh: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/doc-status.sh`
- docs-search.py: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/docs-search.py`
- lenore-docs.py: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/lenore-docs.py`
- docs/CLAUDE.md formatting details: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/docs-CLAUDE.md`
- .gitignore snippet: `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/gitignore-snippet`
- doc-lint.sh (commit-time judgment lint): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/doc-lint.sh`
- doc-lint-judge.md (the lint's judge prompt): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/agents/doc-lint-judge.md`
- doc-hygiene-rules.md (the shared hygiene rulebook — copy to scripts/): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/skills/doc-system/references/doc-hygiene-rules.md`
- doc-health.sh (background health-audit runner — copy to scripts/, chmod +x): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/doc-health.sh`
- doc-health-auditor.md (the audit agent prompt — copy to scripts/): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/agents/doc-health-auditor.md`
- land-guard.sh (landing-flow merge guard — copy to scripts/, chmod +x): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/land-guard.sh`
- truth-candidates.sh (reverse-drift candidate collector — copy to scripts/, chmod +x): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/scripts/truth-candidates.sh`
- reverse-drift-check.md (the shared sync-check contract — copy to scripts/): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/skills/doc-system/references/reverse-drift-check.md`
- code-doc-sync-reviewer.md (the sync reviewer prompt — copy to scripts/): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/agents/code-doc-sync-reviewer.md`
- Codex hooks config (SessionStart status + PreToolUse lint + landing guard): `https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/templates/codex-hooks.json`

When you bump the pin, re-verify each template still matches what's
described in this prompt.

## 1. Setup (same shape as Claude Code's setup flow)

1. Detect whether this repo already has `docs-system:` in its `CLAUDE.md`.
   If so, treat this as an upgrade — diff the repo's copies of the hooks
   and scripts against the templates above and propose replacing any that
   differ. If not, this is a fresh install. Either way, also run an
   **activation check**: verify `git config core.hooksPath` is
   `.githooks`, all four hook files (pre-commit, pre-push,
   pre-merge-commit, commit-msg) exist and are executable, root
   `AGENTS.md -> CLAUDE.md` and `docs/AGENTS.md -> CLAUDE.md` symlinks
   exist, `docs/desk/` and `tmp/` exist (Tier 1; both are gitignored and
   so vanish on a fresh clone), the store root `data/datasets/` +
   `data/experiments/` exists (recreate; also `mkdir -p` each
   `experiments/*/data` symlink's missing `{regen,keep,out}` trio — in a
   linked worktree, symlink `data -> <main worktree>/data` instead), and
   `.codex/hooks.json` registers
   `scripts/doc-status.sh` — repair anything missing, since a fresh clone
   with the marker in `CLAUDE.md` still needs this repaired locally.
2. Ask which tier: Tier 1 (full layout — the system/caveats/playbook
   spine, proposals, journal/notes/tasks/bugs, openspec, experiments,
   desk) or Tier 0 (small repo — `docs/log/`
   only). Default to Tier 1 unless this is clearly a small/experiment repo.
3. For Tier 1: create `docs/{journal,notes,proposals,tasks,bugs,system}/`,
   `docs/desk/`, and `tmp/` (never `docs/reference/` — retired; the hook
   rejects it); seed the spine stubs if absent — `docs/system.md`
   (one-page hub map), `docs/system/premises.md` (named ground
   rules — never numbered, mandatory pre-design read), `docs/caveats.md`
   (named entries + Validity ladders; no entry IDs anywhere in docs), `docs/playbook.md` (Procedures / Tools / Adopted
   research conclusions / Retired candidates) — the exact stub contents
   are in the Claude setup command at
   `plugins/lenore-doc-system/commands/setup.md`, copy them from there;
   create `docs/tasks/project.md` with `## Next`
   and `## Someday` headings if absent; fetch the four hook templates
   (pre-commit, pre-push, pre-merge-commit, commit-msg) into `.githooks/`
   and make them executable; fetch `browse.py`, `doc-status.sh`,
   `docs-search.py`, `lenore-docs.py`, `doc-lint.sh`, `land-guard.sh`,
   and `truth-candidates.sh`
   (plus `doc-lint-judge.md`, `doc-hygiene-rules.md`,
   `reverse-drift-check.md`, and `code-doc-sync-reviewer.md`) into
   `scripts/` (executable);
   fetch `docs-CLAUDE.md`
   into `docs/CLAUDE.md`; append the `.gitignore` snippet (idempotent —
   check its marker line); `mkdir -p data/datasets data/experiments
   data/library`;
   create `experiments/PROMOTIONS.md` (append-only ledger, header +
   comment row); run `git config core.hooksPath .githooks` (stop
   and ask first if it's already set to something else, or `.githooks/`
   already has other hooks — propose chaining, don't overwrite); run
   `git config merge.ff false` and `git config pull.ff true` (no git hook
   fires on a pure fast-forward merge, so forcing merge commits is what
   makes the pre-merge-commit landing guard cover every merge, manual
   ones included; pull.ff true keeps ordinary pulls fast-forwarding);
   symlink
   `AGENTS.md -> CLAUDE.md` at repo root and beside `docs/CLAUDE.md`;
   append the Tier 1 rules block verbatim to the repo's `CLAUDE.md`
   followed by `docs-system: lenore-v1 (tier 1)` (skip the append if the
   marker text is already present — idempotent re-run); append the
   gitignore snippet to `.gitignore` (skip if already present); install
   `templates/codex-hooks.json` as `.codex/hooks.json` in this repo (merge
   into any existing hooks config, never overwrite) — it registers
   `scripts/doc-status.sh` on `SessionStart` and `scripts/doc-lint.sh` as a
   `PreToolUse` hook on Bash (the commit-time judgment lint; copy
   doc-lint.sh, doc-lint-judge.md, doc-hygiene-rules.md, doc-health.sh AND doc-health-auditor.md into `scripts/`, chmod +x the .sh files —
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
1. **Final spec sync.** Apply the change folder's APPROVED deltas to
   `openspec/specs/`, in the same commit style as the rest of the branch.
   Never rewrite specs to match whatever was built: if the built behavior
   diverges from the planned spec, stop and raise it to the user with the
   spec line vs the built behavior side by side — they amend the change
   folder or fix the code.
1b. **Landing doc review.** Read `scripts/doc-hygiene-rules.md` and review
   the branch diff against it — every changed docs/ file and every
   docstring/comment in changed code files (invented entry IDs, opaque
   codenames, history narration in living docs/docstrings,
   reviewer-directed comments), plus check that new living-doc claims
   don't contradict untouched living docs. Fix what you find; note any
   waived finding in the closing journal entry.
2. **Closing journal entry.** Write one
   `docs/journal/YYYY-MM-DD-HHMM-topic.md` entry (line 1 = one sentence,
   ≤10 lines/150 words, no headers/bullets, cite commit hashes) opening
   with "landing <branch>: …". This is fine to write before the merge; if
   the merge/push in step 5 then fails, append a **new** journal entry
   noting the landing did not complete — never edit the first entry
   (journal entries are immutable once committed).
3. **Archive the openspec change folder.** Check its `tasks.md` first:
   ALL boxes checked → archive automatically (`openspec archive <name>`;
   hand-move + spec sync only if the CLI is absent) and just mention it
   in your summary. A FEW boxes pending → never auto-archive; ask the
   user: defer the pending tasks with a pointer (into
   `docs/tasks/project.md` or the closing journal entry) and archive as
   partially adopted, or keep the branch open. Dropped rather than
   completed → archive with a one-line note saying why.
4. **Graduate branch tasks; walk the desk.** If the branch task file
   has a non-empty `## Stakeholder notes` section, offer to compile the
   stakeholder brief first (fetch and follow
   https://raw.githubusercontent.com/Shreeyak/claude-swift-toolbox/72ed171/plugins/lenore-doc-system/commands/brief.md
   — a self-contained HTML report for zero-technical-knowledge readers,
   user reviews before commit; declining is fine, the lines die with
   the file; never compile without the user present). Then open
   `docs/tasks/branch-<slug>.md`; for each open item, graduate it into
   `docs/tasks/project.md` (`## Next` or `## Someday`) or drop it, then
   delete the branch file. Walk `docs/desk/`: default is to unpin (`rm`
   the symlink — desk pins are gitignored, `git rm` won't touch them); if
   the user wants to keep one, add a pointer line to `project.md` first,
   then unpin.
4b. **Reverse-drift sync review — after cleanup, before the merge.** Run
   `scripts/truth-candidates.sh <merge-base> HEAD` and apply the contract
   in `scripts/reverse-drift-check.md` (the reviewer prompt is
   `scripts/code-doc-sync-reviewer.md` — follow it in-session, including
   the embedding channel if `.lenore/embeddings/` exists and the
   per-file coverage-gap docstring recommendations, which you apply
   directly). Save the review verbatim as
   `docs/notes/YYYY-MM-DD-landing-<slug>-sync-report.md` and commit it.
   An evidence-backed `finding` (doc line + quoted claim + code line +
   stated contradiction) blocks this landing until the doc is fixed or
   the finding is waived in the closing journal entry; `clear`/
   `inconclusive`/coverage-gaps never gate. Zero candidates and no
   embeddings index → skip, noting "sync-check: no candidates".
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
read (or fetch) the SKILL.md link above rather than guessing. Bare `git
merge` — into main or ANY other branch — is guarded twice: the Codex
`PreToolUse` hook runs `scripts/land-guard.sh` on agent merge commands,
and the `pre-merge-commit` git hook runs the same check on manual
merges; both fire when the merged branch's `docs/tasks/branch-<slug>.md`
still exists (the landing flow deletes it before merging). Warn-once:
re-running the identical merge proceeds; `LENORE_NO_MERGE_GUARD=1`
skips. `merge.ff false` (set in step 2) is what closes the fast-forward
gap — no git hook fires on a pure ff ref update. The pre-push hook
additionally gates any `git push` that updates main/master; all of this
only applies once `core.hooksPath` is set in this clone (step 1's
activation check exists for exactly this reason).

All repo-local generated state lives under one gitignored `.lenore/`
dir: the semantic index at `.lenore/embeddings/` (moved from the old
`.docs-embeddings/` — docs-search.py migrates automatically) and the
warn-once stamps at `.lenore/stamps/` (moved from `.git/lenore-*`).
Losing `.lenore/` is always safe: the index rebuilds on the next
search, and a lost stamp only re-arms one warning.

## 3. Doc-health audit (Codex-native equivalent of `/doc-health`)

When the status line shows `doc-health: due` (or `never`), or the user
asks for a doc health check: run `scripts/doc-health.sh &` from the repo
root. It creates its own worktree + `doc-health-YYYY-MM-DD` branch from
HEAD, drives the auditor prompt (`scripts/doc-health-auditor.md` + the
rulebook) through `codex exec` inside that worktree, and prints the
branch when done — the current checkout is never touched, and the audit
never merges itself. Relay the report; the user merges the branch (that
merge is what advances the doc-health nag). Never merge it autonomously.
