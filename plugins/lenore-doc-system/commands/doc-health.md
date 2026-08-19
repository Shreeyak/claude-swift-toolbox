---
description: Launch the documentation health audit in the background — corpus-wide truth maintenance by the doc-health-auditor agent (Sonnet) in its own worktree. Triggered by the status line's "doc-health: due/never" nag or on demand.
---

Launch the doc-health audit. The current session does NO audit work and
NO worktree work — it only launches and later relays. Never use
EnterWorktree or cd the user's session anywhere: the auditor gets its
own worktree and the user's session stays exactly where it is.

1. Preconditions (cheap, read-only): the repo has the doc system
   (`docs-system:` marker in CLAUDE.md). Note `git rev-parse HEAD` as
   the base SHA to include in the launch prompt.

2. Launch the auditor **in the background** via the Agent tool:
   - `subagent_type: "lenore-doc-system:doc-health-auditor"`
   - `isolation: "worktree"` — the harness creates the agent its own
     worktree from HEAD; the agent works and commits there; the user's
     checkout is untouched.
   - Prompt: the base SHA, and (if the status line showed it) how long
     since the last check. Nothing else — the agent reads the rulebook
     and its own instructions itself.
   Then tell the user the audit is running in the background and
   continue with whatever else they were doing. Do not poll; the
   completion notification arrives on its own.

3. When the completion notification arrives: relay the auditor's
   one-sentence verdict, the finding counts, the branch name, and its
   "proposed deletions" list verbatim — deletions happen only with the
   user's confirmation, applied as commits on the audit branch.

4. Merging the audit branch is the user's call, now or later. The
   status line's doc-health nag advances only when the audit's journal
   marker entry reaches the current branch — an abandoned audit
   intentionally keeps nagging. If the user says merge and HEAD has
   advanced past the recorded base SHA, check whether files the audit
   edited also changed upstream; if so, say which and offer a re-run of
   just those files instead of a blind merge.

5. Never merge autonomously; if the user is away, step 3's relay is
   your closing summary and the branch waits.

Codex sessions (no Agent tool): run `scripts/doc-health.sh &` — it
creates the worktree itself and drives the same auditor prompt through
a headless backend (`claude -p` on Sonnet when available, else
`codex exec`), prints the branch name when done, and never touches the
current checkout. Relay its output the same way as step 3.

If neither path is available (no plugin agents, no script), give the
user this one-liner to paste into a Claude session instead: "Launch the
lenore-doc-system:doc-health-auditor agent in the background with
worktree isolation; base SHA <sha>; relay its report when it finishes."
