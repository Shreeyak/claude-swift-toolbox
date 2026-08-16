# docs/ — formatting details

This file carries formatting details only. Triggers, routing, and the
enforcement model live in the root `CLAUDE.md`; read that first — this file
tells you the exact shape once you already know when to write.

`AGENTS.md` beside this file symlinks to it, so Codex sees the same rules.

## Journal entries (`docs/journal/YYYY-MM-DD-HHMM-topic.md`)

- First line: one sentence stating the event. No heading markup needed —
  the sentence itself is the entry.
- Everything after: optional support, ≤10 lines / 150 words total. No
  headers, no bullet lists, no code blocks. Cite commit hashes in
  parentheses. Name experiments and restate verdicts inline.
- Catch-up entries (summarizing a gap from `git log`) get double the
  budget: ~20 lines.
- Immutable once committed. Fix typos freely before the commit; never
  after.

```
# 2026-08-15-1432-switch-to-masked-ncc.md

Switched placement from ECC to masked NCC.

Believed ECC would hold at low overlap (assumption from the April web
search). The masked-ncc experiment showed 2.1px vs 5.8px mean error at
<50% overlap. Lifting the mask-generation approach into the placement
pipeline; ECC path removed. (abc1234)
```

## Notes (`docs/notes/YYYY-MM-DD-topic.md`)

- Line 1 is always a one-sentence summary — this is what `browse.py`
  displays. For Markdown notes, strip any leading `#` before writing the
  summary as the actual first line of prose.
- HTML notes: an HTML comment at the very top of the file:
  `<!-- one-sentence summary · published: <url-if-published> -->`
- Immutable once committed. Revisiting a topic = a new dated file, not an
  edit to the old one.
- **A note that corrects or supersedes an earlier note names it in its
  body, in plain words** ("revises notes/2026-08-10-x.md"). The old note
  is not edited, gets no marker, and stays unless it's junk
  (human-confirmed delete). This makes succession discoverable in both
  directions with zero infrastructure: newest-first listings and search
  dates surface the newer note, and grepping an old note's filename
  finds its successors. No need to check for supersession on every
  read — notes are never authority, so an old note can't mislead about
  what's true now; check only when about to act on one (the date+class
  rule already says this).
- **Review output** (subagent/codex/human code reviews): never save the
  raw transcript, and save nothing for findings that were fixed — the
  fix commits are the record. A review earns a note
  (`YYYY-MM-DD-review-<topic>.md`, line 1 = one-sentence verdict) only
  when it holds something that outlives the session: declined findings
  with the reason, or a milestone verdict. Confirmed-but-unfixed bugs go
  to `docs/bugs/` (one file each); design-changing findings go into the
  openspec change/spec, not a note.

## Reference docs (`docs/reference/<topic>.md`)

- Named, not dated. Editable in place — exempt from the immutability
  hook. Update when the external thing (tool, API, workflow) changes.
- For things outside the repo only. Internal project thinking is a note,
  never a reference doc.

## Tasks (`docs/tasks/`)

- `branch-<slug>.md`: your session's scratch on this branch, where
  `<slug>` is the branch name with every `/` replaced by `-`. Write
  freely. Other branches' files are read-only context.
- `project.md`: two headings, `## Next` and `## Someday`. Entries: one-line
  title, then ≤5 lines of context. Longer context becomes a dated note the
  line points to by name — `— details: notes/YYYY-MM-DD-topic.md`. Write
  that note at discovery time, while the context is still in-session; the
  pointer can't rot because notes are immutable and never renamed. Details
  never creep into the task file; whoever picks up the task reads the note
  first. Edited only at landings, with the user's confirmation on what
  graduates.
- **Every task entry must be readable by someone with none of your
  session context.** Mid-task shorthand ("re-run the sweep after the
  τ/μ fix") is the classic failure — a week later nobody knows which
  sweep, which fix, or what τ is. Expand: name the files, commits, and
  parameters; state what triggers the task and what done looks like.
  If self-containment takes more than the title + 5 context lines, that
  is the signal for a backing note, not a longer entry.

## Creating entries — `scripts/lenore-docs.py`

Prefer the CLI for creating notes, bugs, journal entries, and tasks — it
generates correct dated filenames, enforces the shape caps with
explanatory errors, and makes task + backing note + pointer a single
atomic operation (a forgotten pointer becomes impossible). Body goes in
via heredoc:

```
uv run scripts/lenore-docs.py note "One-sentence summary" <<'EOF'
Full prose body...
EOF
scripts/lenore-docs.py note "..." --supersedes notes/2026-08-10-x.md <<'EOF' ... EOF
scripts/lenore-docs.py bug "..." <<'EOF' repro, expected vs actual ... EOF
scripts/lenore-docs.py journal "One-sentence event" [body ≤10 lines/150 words total]
scripts/lenore-docs.py task "Self-contained title" [--someday|--branch] [--note] [context]
```

`task --note` files the body as a dated note and appends the
`— details:` pointer to the task line automatically. Plain Write remains
a valid fallback (the hooks still enforce the rules); the CLI is the
convenient path, not a gate.

## Bugs (`docs/bugs/YYYY-MM-DD-topic.md`)

- Line 1: one-line symptom.
- Then ≤5 lines: file/line anchor, repro steps, suspected cause.
- Deleted in the commit that fixes the bug. A journal entry only if the
  bug or its fix was itself notable.

## Experiment READMEs (`experiments/<name>/README.md`)

Front matter:

```yaml
---
status: exploring | concluded | shelved
verdict: <one sentence, filled in at conclusion>
concluded: YYYY-MM-DD  # only once status leaves "exploring"
---
```

Body sections, in order: `Question`, `What worked`, `What didn't`,
`Lifted into production`, `Not pursued`. Rewritten in place as
understanding sharpens — the README is deliberately mutable, unlike
`runs/`.

## Experiment runs (`experiments/<name>/runs/YYYY-MM-DD-HHMM.md`)

Immutable once committed. Contents: exact command run, config, dataset
identity, code commit hash, metrics, one paragraph of interpretation. Never
edited or deleted after commit — dead ends stay on record.

## Desk (`docs/desk/`)

Managed via plain words, not commands. Symlink name is a short descriptive
label picked by the agent on creation; the human may rename it freely
afterward — renaming the symlink never touches the target.

## Semantic index (`.docs-embeddings/`, optional)

If present, this whole tree (docs/**/*.md, docs/**/*.html,
experiments/*/README.md, experiments/*/runs/*.md, and openspec/**/*.md
except tasks.md) is semantically indexed for
`scripts/docs-search.py`. The index is gitignored and content-hash keyed
per chunk, so new or changed docs are picked up automatically by the next
`docs-search.py` run — no separate reindex step required for routine
edits. See `references/semantic-search-setup.md` in the doc-system skill
if it's missing and you want to set it up.

## Semantic search while coding — the rules

- **Search before designing, not before typing.** Run
  `uv run scripts/docs-search.py "query"` when about to propose a design,
  write an openspec change, or start an experiment — the question is "has
  this repo already explored this?" Trivial edits, mechanical refactors,
  and bug fixes with a known cause need no search.
- **Search on unfamiliar vocabulary.** When a comment, spec, or the user
  uses a project term you can't ground in code, search the term before
  guessing — concepts and vocabulary are what embeddings are for.
- **Before re-running or proposing an experiment, search for its
  verdict.** A concluded experiment's README outranks your intuition.
- **Exact values go to grep, never here.** Numbers, thresholds, flags,
  config keys, error strings, file names, "list every place that…" —
  embeddings retrieve the topic, not the value, and will happily surface
  an adjacent table's figure.
- **Results are pointers, not answers.** Open the top 1-3 files and read
  them; never quote a fact from the result row's summary line alone.
- **Check the date and class before trusting.** Dated files (journal,
  notes, runs, archived changes) are snapshots of what was believed then;
  `openspec/specs/` and `CLAUDE.md` are what's true now. A dated hit that
  contradicts a spec loses.
- **Never cite a figure you found semantically without re-finding it
  exactly** — confirm any number or identifier with grep or by reading it
  at its own line in the opened file. This is the single most common
  failure mode.
- **Low scores mean stop.** If nothing scores well (the tool warns below
  ~0.35), the answer likely isn't in the docs — say so or grep; don't
  stretch a weak hit into support for your design.
- **Phrase queries as concepts, not keyword lists.** A short natural
  sentence naming the idea ("why was GPU-side sorting rejected", "seam
  visibility from feathered blending") retrieves better than bare
  keywords, and one concept per query beats several ORed together. If
  the first phrasing scores weak, rephrase once with different
  vocabulary before falling back to grep.
- **Write for retrieval.** Any doc long enough to split into chunks
  (~1500+ tokens) needs real, descriptive headings — a buried fact is
  found through its section's heading and text. When sibling sections
  hold near-identical content (per-scenario tables, per-arm configs),
  the headings must name what differs.
