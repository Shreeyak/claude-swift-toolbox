---
description: Compile a stakeholder brief for the current branch — a self-contained HTML report for readers with zero technical knowledge, built from the journal span, stakeholder notes, experiment verdicts, and figures
---

# /stakeholder-brief — the stakeholder report

Compile the branch's work into a report for non-technical stakeholders:
executives with **zero knowledge of software, algorithms, or the
software development lifecycle**. Runs at landing (offered by `/land`
step 4 when stakeholder notes exist) or mid-branch on request (an
interim brief — mark it as such in the opening).

This is a GENERATED VIEW over the record, never a second record: every
claim in it must trace to a journal entry, an experiment README
verdict, a spec, or a figure. If the record doesn't support a claim,
the brief doesn't make it.

## 1. Gather sources

- `## Stakeholder notes` in `docs/tasks/branch-<slug>.md` — the
  captured business context. These lines are the report's "why it
  matters" spine.
- `docs/journal/` entries in the branch's date span — the arc,
  including direction changes and abandonments.
- Experiment READMEs touched on the branch — verdict lines only.
- The openspec change folder (or its archive) — what was planned vs
  built.
- Figures: `docs/system/**/figures`-class images, experiment
  `figures/` (curated, human-reviewed), and any images referenced by
  stakeholder notes.

## 2. Write the report

**Output: ONE self-contained HTML file** —
`docs/notes/YYYY-MM-DD-brief-<slug>.html` (single note, immutable once
committed; a later update is a new dated brief). Constraints:

- ALL images embedded as base64 data URIs — the file must render
  complete with no network and no sibling files. Downscale/compress
  images first (longest edge ~1200px, JPEG/WebP); the docs/ hooks
  enforce a 5MB file cap — target well under 2MB.
- Diagrams (pipeline, flow, before/after): PREFER `d2` when the
  binary is installed — write .d2 source, render
  (`d2 --theme <same theme for ALL diagrams> in.d2 out.svg`), inline
  the SVG into the page, and keep each diagram's .d2 source in an
  HTML comment beside it so the next brief re-renders in the same
  style. Fallback without d2: styled HTML/CSS blocks (flex boxes +
  arrows), palette and box/arrow styles defined once in the
  stylesheet. Never a CDN script (mermaid.js etc.) — breaks offline;
  never hand-author long SVG path data. ONE consistent visual style
  across every diagram either way.
- Clean, restrained design: real typographic hierarchy, a small
  palette, generous whitespace. No dashboards, no decoration for its
  own sake.

**Narrative framework — follow one, do not freestyle:**

Hook → Problem → Why it matters → Explanation → Example → Takeaway →
Next steps/CTA. (AIDA — Attention, Interest, Desire, Action — is an
acceptable alternative for short briefs.)

**Writing rules for a zero-technical-knowledge reader:**

- One concept per section, progressive disclosure: each section
  assumes only what earlier sections established. Never two ideas in
  one heading.
- Every abstract idea gets a concrete everyday analogy before any
  explanation ("the pipeline is an assembly line: each station does
  one job to the frame before passing it on").
- Outcomes first, mechanisms nearly absent. "The app now stitches a
  full scan in one pass" — never "rewrote the coordinator."
- Overview altitude, never implementation detail. No config values,
  no edge-case handling, no intermediate steps of how something was
  built — the test is "would this reader decide anything differently
  knowing it?" Give the generic shape of the work; details live in
  the record, not the brief.
- Experiments are reported as a body of work, not one by one: state
  how many experiments the span ran (one sentence or a small stat
  strip — "14 experiments over 3 weeks"), then show RESULTS for only
  the 1–3 most significant, chosen by business impact. The rest exist
  as the number.
- ALGORITHMS ARE THE EXCEPTION to plain-language flattening: the
  novelty and expertise of the work often live in WHICH techniques
  were used, and the brief must not wash that out. At first mention,
  highlight the algorithm's real name (bold), gloss it in one plain
  sentence, and say why using it matters ("phase correlation — a
  technique from signal processing that finds alignment even in noisy
  frames; few consumer apps attempt it"). After first mention, refer
  to it naturally.
- Banned vocabulary: branch, merge, repo, commit, file paths — and
  keep API, backend, refactor, framework names out of the narrative
  spine (they may appear once, defined in a plain sentence, when a
  point genuinely needs them — unlike algorithms they carry no
  novelty signal, so they earn no emphasis).
- Numbers are framed, not dumped: "3× faster — a scan that took a
  minute now takes 20 seconds," with at most one table, formatted for
  scanning.
- Honest costs and risks get their own short section: what was tried
  and abandoned, and what that avoided ("we tested X for a week, it
  failed, which saved building on it"). Executives repeat these
  reports upward — overclaiming is the one unrecoverable error.
- Traceability stays OUT of the visible page (no file paths, no
  commit hashes in prose). Put the claim → source mapping in an HTML
  comment block at the end of the file so a later session can audit
  the brief against the record.

## 3. Review and file

- Show the user the draft (open the file or summarize section by
  section) BEFORE committing — stakeholder wording is judgment work
  and the note is immutable once committed.
- Commit as a normal dated note. Optionally also publish as a private
  artifact page for link-sharing; the committed file remains the
  record of what was reported and when.
- Never run autonomously: an unsupervised session defers the brief
  (see /land step 4) rather than committing stakeholder-facing
  wording without review.
