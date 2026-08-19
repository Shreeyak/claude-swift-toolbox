# Taxonomy review — 2026-08-18

Fan-out review of how the Lenore doc system should classify and home the
knowledge types shrek listed: core docs (architecture / data-flow / state
transitions), app failure modes, domain knowledge, data insights, concept
compendium, discovered tools, literature research, light plans.

Kept for future review and for scoring the shipped design against what was
recommended here.

## Contents

- `01-information-architecture.md` — codex gpt-5.6-sol, IA lens. Verdict:
  widen the living-docs home into an open store of named topic files; no
  new top-level dirs; snapshot→distill promotion.
- `02-agent-workflow.md` — codex gpt-5.6-sol, agent-reality lens.
  Read/update cadence matrix; <5-step filing tree; retrieval without RAG
  (computed index only, no tags, no hand-maintained indexes); hard-limit
  list; write-time routing nudge over refiling passes.
- `03-prior-art-redteam.md` — codex gpt-5.6-sol, prior-art + red-team
  lens. Diátaxis / lab practice / Zettelkasten / wiki-rot / errata
  registries / awesome-lists lessons; 20-session agent-sprawl attack
  table; counter-proposal: exactly three living files (model / caveats /
  playbook) classified by the reader's question, unlimited dated capture
  underneath.
- `04-repo-inventory.md` — Claude Explore agent. Evidence sweep of ~40
  repos under ~/work (1,944 authored docs): per-type abundance, existing
  conventions, the Evascan-Grid misfiling table, and doc types the
  original list missed.
- `05-synthesis.md` — the synthesized proposal presented to shrek, plus
  the standing constraints that shaped it.
- `06-workflow-fit-review.md` — Claude Opus agent. Reconstructed shrek's
  real dev flow from the 54 MB mac-stitch-video quality-gate-rework
  session log and filed 17 real artifacts under the proposed taxonomy
  (4 clean / 5 awkward / 8 no home). Verdict: spine fits settled truth;
  gaps for deferred proposals, cross-cutting premises, multi-file
  bundles, diagram sources, artifact URLs, status surface. Six ranked
  design changes + four user practices to adopt wholesale.
- `07-final-design.md` — the adopted design as shipped (plugin v0.5.0,
  2026-08-20): system/caveats/playbook spine + premises, proposals/,
  research naming + bundles, data/library, candidate systems, figures/,
  artifact URLs, recall wiring, closed-layout enforcement — with each
  deviation from 05 marked to its source (06 review or user answer).

## Standing constraints (user feedback, binding)

- **No decision records / ADRs, ever.** "Pain in the ass, absolute wrong
  type for fast-moving solo projects." `decisions.md` stays on the hook's
  deny-filename list.
- **Naming is greenfield** — nothing adopted yet (Evascan-Grid is only
  testing); rename anything if a better shape wins.
- **Anti-sprawl limits must be enforced, not advised** — agents "take a
  shape and run with it till the whole system gets out of hand."
