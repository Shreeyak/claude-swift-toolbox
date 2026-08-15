<!-- lenore:rules:start (tier 0) — managed by lenore-doc-system; edits inside this span are overwritten on upgrade -->
## Documentation rules   (Tier 0 — small repo)

- This repo is Tier 0: docs-system: lenore-v1 (tier 0).
- Journal and notes are merged — the split is noise at this scale. All
  documentation lives in docs/log/, one dated file per entry:
  YYYY-MM-DD-topic.md (or YYYY-MM-DD-HHMM-topic.md if more than one
  entry lands the same day).
- First line of every file is a one-sentence summary of the event or
  topic. Everything after is optional support, kept short.
- Immutable once committed; before commit, typos and errors may be
  fixed freely. Never edited after that, never given IDs or statuses.
- Write directly, in the same message the trigger occurs — no staging
  area, no filing step. Trigger on milestones (a phase or experiment
  concludes, direction changes) — never per-commit.
- No tracking docs of any kind: no decisions.md, state.md, STATUS.md,
  CHANGELOG.md, HANDOFF.md, TASKS.md. Current truth (if this repo has
  any beyond the code) lives in CLAUDE.md invariants only.
- No docs/tasks/, docs/bugs/, docs/reference/, or desk/ machinery —
  those exist to manage long-lived branches and multiple sessions.
  If this repo grows into needing them, that's the signal to migrate
  to Tier 1 (see the doc-system skill's setup command).
- docs/log/ is the whole index: `ls docs/log/` sorted by name is the
  timeline. No maintained index file.
<!-- lenore:rules:end -->
