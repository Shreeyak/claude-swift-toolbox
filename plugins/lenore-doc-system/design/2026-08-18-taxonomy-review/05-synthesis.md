# Synthesis — proposal as presented 2026-08-18 (pre-adoption, under discussion)

## Where the analysts landed

IA designer: widen the living-docs home into an open store of named topic
files. Workflow analyst: same direction, capped (~24 files, naming
conventions, write-time routing nudge, computed index only). Prior-art
red-teamer: both are wikis; wiki failure = ambiguous authority; proposed
exactly THREE living files classified by the reader's question, not
content type. Corpus evidence arbitrates: failure modes = strongest genre
(stable-ID registry pattern proven); domain knowledge = largest (~90
files, too big for one file); glossaries absent; data insights + tools
homeless; Evascan notes/ already holds six types.

## Proposed design (v1, before user challenges)

Three spine files + bounded chapter escape:

    docs/model.md      how it works NOW (architecture, data flow, state,
                       domain knowledge, vocabulary)
    docs/caveats.md    where it fails NOW (app failure modes w/ stable
                       IDs + data hazards)
    docs/playbook.md   how we work (procedures, evaluated tools w/
                       "use when" + last-verified, adopted literature
                       conclusions)
    docs/model|caveats|playbook/   chapter files only when a spine
                       section outgrows; pointer stays in spine; capped
    journal/ notes/ bugs/ tasks/ desk/ experiments/  unchanged
    reference/ retired -> playbook; no research/ insights/ concepts/
    tools/ knowledge/ dirs; NO decision records (banned)

Ten-second routing: observed/uncertain → dated note (escape hatch, always
legal) · feature contract → spec · belief about how it works → model ·
condition to account for → caveats · repeatable procedure/tool → playbook
· repair intent → bug · later → task line. Promotion demand-driven, never
an inbox.

Hard limits (hook): closed set of docs/ children; spine always exists
(seeded); chapter cap (3+~9); caveat entry shape; playbook entry needs
"use when"+last-verified; no tags/frontmatter in ordinary docs; no
hand-maintained indexes. Never capped: notes, journal, bugs, experiments.
Status counters (not blockers): living docs stale 90d+, spine near size
ceiling, chapter count near cap.

## User challenges raised immediately (2026-08-18, open)

1. model.md as a single file is too much — user won't read a file that
   large, and architecture/data-flow/state docs frequently carry IMAGES.
   → Design must be hub-and-chapters from day one, images beside chapters.
2. Research docs: why is research/ "invisible"? (Answer: only because
   current browse/embeddings index the known homes — fixable by decree.)
   The system may change to index it. User wants the folded workflow
   spelled out before deciding; research outputs in the corpus are often
   multi-file BUNDLES (jina-docs 15 files, insight-extraction 70), which
   flat dated notes handle poorly.
3. How exactly do embeddings get wired into experiment creation and
   openspec proposals? (Answer: CLI prints top-5 semantic hits as part of
   its own output — a tool-output nudge, not agent memory.)
4. Where do core docs of an exploratory candidate system live (e.g.
   mac-stitch experiments/simple-pipeline, "not actually an experiment")?
5. Pending: an Opus agent is reviewing the live quality-gate-rework
   conversation (54 MB jsonl) to score the proposed system against the
   user's actual development flow (research reports, proposals,
   experiments, review reports, domain discoveries, a shared artifact).

Nothing in this file is adopted; it is the state of the discussion.
