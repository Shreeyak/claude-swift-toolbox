# Repo inventory — evidence sweep (Claude Explore agent, 2026-08-18)

Scanned ~/work (~40 git repos, pruned deps/build dirs and the plugin repos).
11,934 raw .md → 1,944 authored knowledge docs. Ground-truth repos:
cambrian/mac-stitch-video (richest hand-rolled taxonomy) and
cambrian/Evascan-Grid (only Lenore adopter).

## Per-type abundance

- **Type 1 core current-truth docs: ABUNDANT (~40+).** mac-stitch
  docs/architecture.md (delegates *how* to algorithms.md), docs/reference/
  tracking-statechart.md (self-contained state doc), eva-cloud
  cell-counting-explained.md (end-to-end data flow). Live in
  docs/architecture.md, docs/reference/, docs/NN-name.md. Maintained in
  active repos, abandoned in old ones.
- **Type 2 failure modes: ABUNDANT, first-class genre (~15+).** THREE
  repos independently invented registries: mac-stitch
  wsi-stitching-failure-modes.md ("regression registry", stable IDs like
  A16 cross-referenced from other docs), lessons.md; vtt-lantern
  mistakes.md (append-only); eva-cloud known-issues.md (confidence-rated);
  beluga HARDWARE_PARITY_GAP.md. Strongest evidence in the corpus.
- **Type 3 domain knowledge: ABUNDANT, largest genre (~90+).**
  cellpose3-cyto3-model-report.md; SP20_PIPETTE_ANALYSIS.md (76-page
  vendor manual distilled); cowork wsi-docs-reference-n-research/ (~70
  files incl. 380 ChatGPT conversations mined → 69 transcripts);
  porting-notes.md pinned to upstream commits. Good ones carry provenance
  (pinned versions, source doc) by hand.
- **Type 4 data insights: PRESENT, under-named (~12).** cellpose-ios
  docs/datasets.md ("every corpus evaluated — used, rejected — and what we
  learned"); mac-stitch frame-archive-survey-2026-08-16.md;
  test-wsi-images.md (chosen to probe the failure envelope). No
  convention at all.
- **Type 5 concept compendia: EFFECTIVELY ABSENT.** Zero standalone
  glossaries in 1,944 docs. Docs declare self-containment inline instead
  (tracking-statechart: "defines every term it uses"). wiki-shrek has a
  concept *recipe* but ~1 filled entry. A type to seed, not collect.
- **Type 6 tools: PRESENT, scattered across FOUR conventions (~25).**
  docs/workflow/code-intelligence-tools-survey.md; vtt-lantern
  docs/research/tile-layer-libraries.md (explicit shelf-life rule) and
  agent-skills-and-plugins.md ("dated verdicts, not standing truth");
  wiki-shrek ai/tools.md MOC tables; cambrian-ios-camera docs/tooling.md.
- **Type 7 research: ABUNDANT; docs/research/ is a live convention in 6
  repos.** mac-stitch docs/research/2026-06-01-v5-phase-correlation-
  wraparound.md (superseding banner pattern); experiments/mac-icecc/
  research-narrative.md (candid narrative explicitly paired with terse lab
  record); datasheet-rag rag/experiments/exp01..15/FINDINGS.md synthesized
  upward into EXPERIMENT-CHRONICLE.md + RECOMMENDATIONS.md; jina-docs/
  (15 vendored upstream files as a reference shelf).
- **Type 8 plans: ABUNDANT but largely fossilized (~50).** cellpose-ios
  future-ideas.md; mac-stitch docs/proposals/ (11 files, lifecycle in
  filename: ...-IMPLEMENTED.md); Evascan placement-accuracy-plan.md
  (plan retired into notes with "where it disagrees, they win" clause);
  ANDROID PLAN_*.md abandoned since 03/2026.

## The Lenore adopter's misfiling table (Evascan-Grid)

docs/notes/ holds SIX types at once: an architecture outline (type 1), a
drift failure-mode characterization (type 2), a concept piece
(measurement-trust, type 5), a measurement report (type 4), a retired plan
(type 8), handoffs, a tooling map, and branch scratch. Five of eight
08-15 notes are marked "Carried over verbatim from the retired
docs/decisions.md" — a decisions log dissolved into undifferentiated notes
because there was no better slot.

## Patterns the user builds when hand-rolling

- mac-stitch docs/INDEX.md: tier dashboard (Canon / Evidence / History /
  Deferred) with a browse contract — "for current context, read Canon +
  INDEX only". Dirs: research/ proposals/ reviews/ reports/ reference/
  workflow/ history/{diagnostics,archived}/ v3-arch/ (.d2 + rendered .png
  architecture diagrams, as-built vs designed pairs). Rules written in
  docs/workflow/doc-organization.md + doc-style.md.
- wiki-shrek: explicit type system (recipes for article/concept/image/
  note/paper/show/tool; YAML type: frontmatter; raw/ → sources/ → topics/
  → index MOCs; lint audits). Closest existing artifact to the taxonomy
  being designed.
- Near-universal: .remember/{now,recent,archive,today-*}.md session state
  (12+ repos) — orthogonal to the 8 types.

## Types the original list missed

1. Handoff/continuation briefs (~15; most-repeated filename in corpus).
2. Decision records (4 repos; one "CLOSED TO NEW ADRs") — user has since
   BANNED the type.
3. Workflow/house-rules docs (mac-stitch docs/workflow/, 11 files).
4. Measurement/experiment reports distinct from research narrative
   (FINDINGS.md × 15; "terse lab record vs narrative" split stated
   explicitly in mac-icecc).
5. Status/story orientation pair (vtt-lantern docs/status.md +
   docs/story.md: present-tense state vs narrative arc).
6. Doc-system meta docs (INDEX.md, recipes, lint logs) — appear whenever
   doc count passes ~20.
