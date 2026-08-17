<!-- lenore:rules:start (tier 1) — managed by lenore-doc-system; edits inside this span are overwritten on upgrade -->
## Documentation rules   (Tier 1 — full system)

- Write documentation directly, in the same message the trigger occurs.
  There is no staging area and no filing step.
- Journal: one file per entry in docs/journal/, named
  YYYY-MM-DD-HHMM-topic.md. Immutable once committed; before commit,
  typos and errors may be fixed freely. Triggers: openspec phase
  completed, experiment concluded, direction changed, branch
  landed/abandoned, catch-up when the status line shows a gap; on
  branches with no change folder, one entry per concluded work-topic.
  Never per-commit.
  Shape: first line = the event in one sentence; ≤10 lines / 150 words
  total; no headers, bullets, or code blocks; cite commit hashes; name
  experiments and restate verdicts inline. Overflow becomes a dated
  note, never a longer entry. The journal is non-authoritative history:
  never edited, never given IDs or statuses, never treated as a source
  of current truth.
- Current truth lives ONLY in openspec/specs/ (updated in the same
  commit as the code), this file's invariants, and experiment READMEs.
- Cross-references: cite commit hashes; name dated files or experiment
  folders in plain words. One-way only. Never IDs, never code→doc
  links, never link-consistency checks.
- docs/tasks/branch-<slug>.md is this session's scratch — write freely;
  other branch files are read-only. `<slug>` is the branch name with
  every `/` replaced by `-` (branch `feature/x` -> `branch-feature-x.md`).
  project.md is edited at landings, items graduating only with the
  user's confirmation. Entries: one-line title + ≤5 lines context; more
  becomes a note.
- docs/notes/YYYY-MM-DD-topic.md for all ad-hoc artifacts, including
  architecture snapshots (stamp the source commit). Immutable once
  committed.
- Bugs: when a bug is noticed — by an agent mid-task or the user at
  any time — file docs/bugs/YYYY-MM-DD-topic.md immediately: one-line
  symptom, then ≤5 lines (file anchor, repro, suspected cause). Do not
  derail the current task to fix it. The session that fixes a bug
  deletes its file in the fix commit; journal entry only if notable.
  ls docs/bugs/ is the live bug list.
- Experiment runs: immutable files in runs/ with command, config,
  dataset, code commit, metrics, one-paragraph interpretation. README
  front-matter (status/verdict) updated at conclusion, same session,
  with a journal entry.
- For experiment outcomes, query live:
  grep -H "^verdict:" experiments/*/README.md
- docs/ contains prose and images only: .md, .html, images (a
  pre-commit hook enforces this). Experiments live at repo root: code
  and outputs in the experiment folder (heavy artifacts gitignored),
  run records and README as .md alongside them.
- The first line of every note and journal entry is a one-sentence
  summary — browse.py displays these. HTML notes: an HTML comment at
  the top with the summary, plus "published: <url>" if uploaded as a
  web artifact. Docs built FOR the user (reports, diagrams, artifacts)
  are notes like any other.
- Prefer scripts/lenore-docs.py (note|bug|journal|task, body via
  heredoc) for creating doc entries — it generates dated filenames,
  enforces shape caps with explanatory errors, and links task + backing
  note atomically. Plain Write stays valid.
- Task entries in docs/tasks/project.md must be readable with none of
  this session's context: name the files, commits, and parameters — no
  "the fix" / "the sweep" shorthand. Context beyond 5 lines becomes a
  dated note the entry points to ("— details: notes/...").
- Need an index of existing docs/experiments? Run
  scripts/browse.py --plain (or --json). Never write an index file.
- docs/reference/<topic>.md holds living how-tos for external things
  (tool integrations, workflow setups, research references). Named,
  not dated; editable in place. Internal project thinking goes to
  notes/, never here.
- Throwaway files — scratch scripts, hack-plans, one-off outputs — go
  in tmp/ (gitignored wholesale). Anything worth keeping graduates
  out of it. Never write scratch files anywhere else in the repo.
- Every script in scripts/ opens with two comment lines: "# usage:"
  and "# what it does". No scripts/README.md.
- The desk: when you produce a doc FOR the user (diagram, comparison,
  requested research), save it in its normal home and symlink it into
  docs/desk/ under a short descriptive name, in the same message.
  "Put on / take off my desk" in the user's words does the same.
  "Delete it" also git rm's the original — allowed for notes,
  reference, bugs, tmp; never journal or runs. Never delete or prune
  the desk unprompted; when working autonomously, defer desk and
  pruning decisions to the next interactive session instead of
  guessing.
- Before drafting a proposal/design, or when a question may have been
  investigated before, search docs/notes/ and experiment READMEs
  (grep or browse.py --plain). Notes carry no status markers: old
  ones sink, wrong ones are history, junk gets deleted by the user.
- Concept/vocabulary questions over past docs ("did we explore X?"
  phrased differently than the docs' own wording): run
  scripts/docs-search.py "<query>" if .docs-embeddings/ exists in this
  repo; otherwise fall back to grep + browse.py --plain.
- Doc formatting details (entry shapes, front-matter fields) live in
  docs/CLAUDE.md; the triggers and routing in THIS file apply during
  all work, everywhere in the repo.
- Landing = merging into main or abandoning a branch. Run the landing
  flow; the merge is its final step. Never merge or push to main
  outside it. The landing markers are structural: branch task file
  deleted, change folder archived — the pre-push gate checks these.
- Deleting or pruning doc content requires showing the user the diff.
  Writing new content does not.
- Do not create state.md, decisions.md, STATUS.md, CHANGELOG.md,
  HANDOFF.md, PLAN-*.md, HANDOFF-*.md, REVIEW-*.md, or any new
  tracking doc. Review findings worth keeping go in a dated note. (A hook
  enforces this for that
  specific list of names as a representative sample — the rule is the
  doctrine, not the list: any file whose job is "current status/decision
  tracking outside openspec/specs and CLAUDE.md" is out, hook-caught or
  not.)
<!-- lenore:rules:end -->
