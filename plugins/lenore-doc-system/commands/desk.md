---
description: Review the desk — list pins with summaries and ages, prompt renew-or-drop for stale ones, suggest unpinned docs
allowed-tools: Bash(ls:*), Bash(git:*), Bash(rm:*), Bash(ln:*), Bash(stat:*), Bash(find:*), Read, Glob, Grep
---

Show the user their desk (`docs/desk/` — a gitignored directory of symlinks
to the docs that matter right now) and walk the review with them. This is
an interactive command: if the session is operating autonomously (a
standing "don't wait on me" instruction), do not run the review — desk
decisions are deferred to interactive sessions.

## 1. List the desk

For each symlink in `docs/desk/`, show one line:

- the pin's name (the symlink's basename — the human chose or approved it),
- the target's first line (which is a one-sentence summary by rule; for
  HTML, the first `<!-- ... -->` comment),
- the pin's age (the **link's** mtime, not the target's — `stat -f %m` on
  macOS),
- a `stale` marker if the link is older than 14 days,
- a `dangling` marker if the target no longer exists (e.g. a bug file
  deleted in its fix commit).

If the desk is empty or the directory doesn't exist, say so and skip to
step 3.

## 2. Renew-or-drop for stale and dangling pins

For each `stale` pin, ask: renew or drop?

- **Renew** = the user still wants it — refresh the link's mtime
  (`touch -h`) so the 14-day clock restarts. Renewal is a deliberate act;
  never renew silently.
- **Drop** = remove the symlink with `rm` (never `git rm` — pins are
  untracked). The target document is not touched.
- If the user says **delete**, also `git rm` the target — allowed only for
  notes, reference docs, bugs, and tmp files; **never** journal entries or
  run records (the pre-commit hook enforces this — for those, just drop
  the pin). Show the deletion as a diff before committing.

`dangling` pins are removed without asking (there is nothing behind them);
mention them in one line.

## 3. Suggest what's missing

List up to five unpinned candidates the user may want on the desk:

- docs added on the current branch (`git log <default>..HEAD --diff-filter=A
  --name-only -- docs/` — dedupe, keep .md/.html),
- docs touched in the last 7 days that aren't pinned.

Suggestions only — pin nothing without the user saying so. If they name
one, create the symlink (`ln -s` with a relative target) under a short
descriptive name.

## Notes

- Plain words always work outside this command ("put X on my desk", "take
  it off", "delete it") — this command is just the batched review of the
  same mechanism.
- Never clear the desk wholesale here; that only happens in the landing
  flow's desk walk, with the user present.
