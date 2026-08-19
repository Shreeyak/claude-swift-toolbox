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
  commit as the code), this file's invariants, experiment READMEs, and
  the docs/ spine: docs/system.md + docs/system/ chapters (how it works
  now — update a chapter in the same commit that falsifies it),
  docs/caveats.md (where it fails now — named entries, each a
  Validity ladder: Confirmed / Mechanism / Retracted, read in order),
  docs/playbook.md (procedures, evaluated tools with use-when +
  last-verified, adopted research conclusions).
- Never invent serial, ordinal, categorical, date-based, or otherwise
  systematic identifiers for doc entries — no C1/P3/ADR-### style
  designations, no ordering/priority prefix schemes, anywhere in docs
  or docstrings. Entries that need referencing get a short descriptive,
  content-derived slug name (heading or bolded lead) and are cited by
  name in plain words ("the seam-drift caveat"). Carve-out: identifiers
  belonging to the documented domain (P95, RFC 9110, commit hashes,
  issue numbers, run012 experiment records) are fine to write ABOUT —
  never repurpose one to organize docs. When a reference justifies a
  decision, warning, or non-obvious claim: state the claim in one
  sentence, then the greppable locator — "NCC drifts near seams, so we
  mask first (docs/caveats.md, seam-drift-at-low-overlap)"; never a
  bare pointer or a date alone. Deleting the locator must leave a
  sentence that still states the claim; the entry is authoritative if
  the summary drifts.
- Before drafting a proposal, design, or experiment, read
  docs/system/premises.md — the named ground rules about the
  product, instrument, and operator that hold regardless of
  implementation. Name the premises the design rests on or bends.
- Designed-but-not-committed work goes to docs/proposals/
  YYYY-MM-DD-topic.md — the ONE revisable dated class, front-matter
  status: proposed|accepted|deferred|superseded|implemented
  (hook-checked). Create via scripts/lenore-docs.py proposal — it also
  appends the task pointer to project.md; a proposal without a pointer
  is unreachable and gets flagged. accepted -> becomes an openspec
  change; implemented -> conclusions land in the spine.
- Cross-references: cite commit hashes; name dated files or experiment
  folders in plain words. One-way only. Never IDs, never code→doc
  links, never link-consistency checks.
- docs/tasks/branch-<slug>.md is this session's scratch — write freely;
  other branch files are read-only. `<slug>` is the branch name with
  every `/` replaced by `-` (branch `feature/x` -> `branch-feature-x.md`).
  project.md is edited at landings, items graduating only with the
  user's confirmation. Entries: one-line title + ≤5 lines context; more
  becomes a note.
- docs/notes/YYYY-MM-DD-topic.md for all ad-hoc dated artifacts and for
  anything you're unsure how to file (the escape hatch — a dated note is
  never wrong). Immutable once committed. Research output (literature/
  online surveys) is named YYYY-MM-DD-research-<topic>.md. A note may be
  a DIRECTORY (dated bundle with an index.md) only when it holds members
  that are not your own prose — downloaded sources, .csv/.json evidence,
  figures + sources, other agents' reports; commit the bundle when the
  effort concludes. Papers/PDFs are never committed: bytes go to
  data/library/<topic>/ in the store, listed in the note by store path.
- Bugs: when a bug is noticed — by an agent mid-task or the user at
  any time — file docs/bugs/YYYY-MM-DD-topic.md immediately: one-line
  symptom, then ≤5 lines (file anchor, repro, suspected cause). Do not
  derail the current task to fix it. The session that fixes a bug
  deletes its file in the fix commit; journal entry only if notable.
  ls docs/bugs/ is the live bug list.
- Experiments: one dated dir experiments/YYYY-MM-DD-<name>/ — README
  (current truth: question/status/verdict front-matter + Findings etc.,
  no narrative), code at the root, notebook/ (one immutable runNNN entry
  per run: outcome sentence, command/commit/inputs/outputs anchors, What
  happened + Interpretation prose; promoted artifacts named after their
  run), and a committed data symlink into the gitignored /data/ store
  (regen/ keep/ out/<runid>/). Raw outputs go ONLY to the store:
  experiments/<name>/data/out/<runid>/ (mkdir it first — that reserves the run id); git-worthy keepers are
  promoted by copy into notebook/. README front-matter (status/verdict)
  updated at conclusion, same session, with a journal entry. Catch-up:
  read the README, then cat notebook/*.md. Shapes: docs/CLAUDE.md.
- For experiment outcomes, query live:
  grep -H "^verdict:" experiments/*/README.md
- docs/ is a CLOSED layout (hook-enforced): top level holds only
  CLAUDE.md, system.md, caveats.md, playbook.md and the dirs system/
  caveats/ playbook/ proposals/ notes/ journal/ bugs/ tasks/ desk/.
  Never invent a new docs/ home — route by question, or file a note.
  Prose everywhere; figures + their editable sources (.d2/.excalidraw/
  .mmd/.py) beside spine chapters and inside note bundles; .csv/.json
  only inside bundles; 5MB/file cap. Experiments live at repo root;
  their bytes live in the /data/ store, joined to notebook entries by
  run id; curated human-reviewed images go in experiments/<name>/figures/.
- The first line of every note and journal entry is a one-sentence
  summary — browse.py displays these. HTML notes: an HTML comment at
  the top with the summary, plus "published: <url>" if uploaded as a
  web artifact. Docs built FOR the user (reports, diagrams, artifacts)
  are notes like any other.
- Prefer scripts/lenore-docs.py (note|bug|journal|task|proposal, body
  via heredoc) for creating doc entries — it generates dated filenames,
  enforces shape caps with explanatory errors, links task + backing
  note (and proposal + pointer) atomically, and surfaces related prior
  work (recall) when creating proposals and experiments. Plain Write
  stays valid.
- Task entries in docs/tasks/project.md must be readable with none of
  this session's context: name the files, commits, and parameters — no
  "the fix" / "the sweep" shorthand. Context beyond 5 lines becomes a
  dated note the entry points to ("— details: notes/...").
- Need an index of existing docs/experiments? Run
  scripts/browse.py --plain (or --json). Never write an index file.
- There is no docs/reference/: external-tool how-tos live in
  docs/playbook.md (use-when + last-verified per tool); internal
  explanations in docs/system/ chapters; dated research in notes/.
- Experiments exploring a whole alternative architecture (not a
  question) set kind: candidate-system in their README: exempt from
  dated name/runNNN/store, required to carry a document-map section, a
  "Dead ends & ruled out" register, and a terminal verdict
  (adopted -> docs copied to docs/system/ + PROMOTIONS line;
  retired -> playbook registry line naming the git tag; parked ->
  status flip with the unpark condition). Their design docs stay INSIDE
  their dir until adoption.
- A published claude.ai artifact's URL is recorded where the file
  lives: front-matter artifact: (proposals, experiment READMEs) or
  "published: <url>" in an HTML file's top comment — the status line
  flags committed HTML with no recorded URL.
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
  reference, bugs, tmp; never journal or notebook entries. Never delete or prune
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
