The cleanest taxonomy is to widen `docs/reference/` into the repo’s single living knowledge store. Do not add separate `knowledge/`, `insights/`, `failure-modes/`, or `research/` homes.

The governing distinction becomes:

- “What was observed, studied, or believed on a date?” → immutable `docs/notes/`
- “What should a competent agent believe now?” → editable `docs/reference/`
- “What behavior does the product promise now?” → `openspec/specs/`
- “What work might or will we do?” → `docs/tasks/` or `openspec/changes/`
- “What did an empirical trial establish?” → `experiments/`

This preserves the history/current-truth split while giving current explanatory knowledge a real home.

## Decisions for the eight types

| Type | Decision | Mutability and cadence | Rationale |
|---|---|---|---|
| 1. Architecture, data flow, state transitions | **Existing home with a rule tweak:** `docs/reference/` | Living; update in the same change that makes the explanation materially false | Widen `reference/` beyond external systems. OpenSpec specs remain normative feature truth; reference docs explain cross-cutting system structure. |
| 2. Detected failure modes | **Existing homes with a routing tweak:** `docs/bugs/`, `docs/notes/`, or `docs/reference/` | Bug: disposable until fixed. Note: immutable observation. Reference: living accepted failure model | An actionable discrepancy with expected behavior is always a bug. An isolated observation is a note. A recurring limitation, operational hazard, or accepted failure envelope belongs in living reference. |
| 3. Domain knowledge | **Existing home with a rule tweak:** `docs/reference/` | Living; update when evidence or the project’s working model changes | Agents need one current domain model, not a chronological pile of surveys. The dated research that produced it may remain in notes. |
| 4. Data insights and anomalies | **Existing homes with a snapshot→distill rule:** `docs/notes/`, `experiments/`, then sometimes `docs/reference/` | Raw finding: immutable. Experiment findings: living README plus immutable runs. Durable operational conclusion: living reference | Preserve exactly what was observed against which dataset, but promote conclusions that future work should rely upon. |
| 5. Useful concepts | **Existing home with a rule tweak:** `docs/reference/` | Living; update when terminology or understanding changes | A compendium is current explanatory knowledge. Split by coherent topic rather than maintaining one giant glossary. |
| 6. Discovered tools | **Existing home as-is:** `docs/reference/` | Living once validated; update when the tool or integration changes | “Found something potentially interesting” is only a note. Create a reference doc after verifying that the tool is useful enough that somebody should be able to use or evaluate it later. |
| 7. Literature-survey research | **Existing homes with a rule tweak:** `docs/notes/` plus `experiments/`; distill into `docs/reference/` when warranted | Survey artifact: dated and immutable. Empirical augmentation: experiment lifecycle. Current synthesis: living reference | “Research” is an activity, not a distinct mutability class. A separate `research/` tree would reproduce notes, reference, and experiments under another name. |
| 8. Plans arising from observations | **Existing homes with a rule tweak:** `docs/tasks/` or `openspec/changes/` | Task: editable/disposable queue item. Change: living while in flight, archived at landing | A lightly formed intention is not yet a specification. Promote it to an OpenSpec change once it has a coherent deliverable, proposed behavior, and completion boundary. |

## The important `reference/` change

Replace:

> For things outside the repo only.

With:

> Named, editable documents containing knowledge that a competent contributor should treat as current: internal system explanations, domain models, durable data conclusions, known failure envelopes, concepts, and external tools or integrations.

This also requires retiring the settled rule “No standing ARCHITECTURE.md.” That rule solves staleness by refusing to represent an important class of current truth. The better rule is narrower:

> No architecture history or design deliberation in living reference. `docs/reference/architecture.md` describes only the current system; dated snapshots and rejected designs remain notes or archived changes.

Authority should remain explicit:

- `openspec/specs/`: normative product behavior and requirements.
- `docs/reference/`: current explanatory and operational knowledge.
- `CLAUDE.md`: short invariants and contributor instructions.
- Code and tests ultimately expose drift; reference docs change atomically when code invalidates them.

## Mechanical filing test

An agent should be able to file with five questions:

1. Is this an actionable product discrepancy? File a bug.
2. Is this evidence or thinking tied to today, a dataset, source set, or investigation? File a note or experiment record.
3. Should a future agent rely on this as the best current explanation? Update or create a reference doc.
4. Is this merely an intention without a designed change? Put it in tasks, with a backing note if needed.
5. Does it define a coherent product change and its done condition? Create an OpenSpec change.

The snapshot→distill pattern should be available, not mandatory ceremony. Do not create both a note and reference doc for every discovery. Capture a note when provenance and historical context matter; distill only when the conclusion becomes reusable, repeatedly encountered, or necessary for correct future action.

## Proposed tree

```text
CLAUDE.md                         short hub, invariants, documentation rules

openspec/
  specs/                          normative as-built product behavior
  changes/<name>/                 designed or committed work
  changes/archive/                completed or dropped changes

docs/
  CLAUDE.md                       document shapes and filing rules

  journal/
    YYYY-MM-DD-HHMM-topic.md      immutable project arc

  notes/
    YYYY-MM-DD-topic.md           immutable observations, surveys, analyses,
                                  architecture snapshots, research and anomalies

  reference/                      all living explanatory knowledge
    architecture.md               current system structure
    data-flow.md                  current cross-component flow
    state-transitions.md          current lifecycle/state model
    failure-modes.md              known limitations and operational hazards
    <domain-topic>.md             current domain knowledge
    <dataset-or-data-topic>.md    durable data properties and caveats
    <concept-topic>.md            reusable concepts and vocabulary
    <tool-or-integration>.md      external tools, APIs and workflows

  bugs/
    YYYY-MM-DD-topic.md           live actionable defects

  tasks/
    project.md                    Next and Someday intentions
    branch-<name>.md              disposable branch working memory

  desk/                           gitignored human-facing symlink pins

experiments/
  PROMOTIONS.md
  YYYY-MM-DD-<question>/
    README.md                     current experimental synthesis
    notebook/                     immutable run evidence
    ...

data/                             gitignored datasets and experiment outputs
tmp/                              gitignored throwaway material
```

Keep `docs/reference/` flat initially. Descriptive filenames plus `browse.py` summaries make it easier to scan than a prematurely nested taxonomy. If a repo eventually has many domain or tool documents, ordinary topical subdirectories can be earned locally; they should not be part of the base system.

## One-line rule for every home

- `CLAUDE.md`: Put only durable rules and invariants every agent must see immediately.
- `openspec/specs/`: State the product behavior the implemented system currently promises.
- `openspec/changes/`: Put designed work with a coherent outcome and definition of done.
- `docs/journal/`: Record immutable milestones and belief changes in the project’s story.
- `docs/notes/`: Capture dated evidence, analysis, research, and thinking without claiming current authority.
- `docs/reference/`: Maintain the best current explanation a future contributor should rely upon.
- `docs/bugs/`: Track reproducible, actionable discrepancies until the fixing commit removes them.
- `docs/tasks/`: Park intentions that are actionable but not yet designed as OpenSpec changes.
- `docs/desk/`: Pin the few documents the human currently wants in view.
- `experiments/`: Keep question-driven empirical work, its current verdict, and immutable run evidence.
- `data/`: Store datasets and raw experimental bytes, never documentary truth.
- `tmp/`: Put things that may disappear without a decision.

## Failure-mode routing examples

- “Saving twice corrupts the cache; expected idempotence” → `docs/bugs/`
- “The OCR model often merges columns below 120 DPI” → `docs/reference/failure-modes.md`
- “Dataset v3 had 41 malformed rows on 2026-08-18” → dated note or experiment run
- “Malformed rows are an enduring property of the upstream export” → distill into the relevant living data reference
- “We might add a confidence gate for low-DPI OCR” → `docs/tasks/project.md`
- A designed confidence-gate behavior with acceptance cases → `openspec/changes/confidence-gate/`

## What I would explicitly not add

- No `docs/knowledge/`: it would be indistinguishable from widened `reference/`.
- No `docs/insights/` or `docs/anomalies/`: these describe content, not lifecycle; use notes, experiments, or living reference according to authority.
- No `docs/failures/`: bugs and known failure envelopes have meaningfully different lifecycles.
- No `research/`: surveys are notes, current synthesis is reference, and empirical work is experiments.
- No `plans/`: light intentions belong in tasks; designed plans belong in OpenSpec changes.
- No mandatory promotion ledger, tags, status front matter, or source database for knowledge docs.
- No single `concepts.md`, `domain.md`, or universal `knowledge.md` once it becomes long; coherent named topics retrieve better and reduce edit conflicts.
- No automatic duplication of every note into reference. Promotion is a judgment triggered by reuse or reliance.

## The genuinely contestable decisions

1. **Widening `docs/reference/` to internal current truth.** This is the largest philosophical change, but I think it is necessary. OpenSpec alone cannot comfortably express architecture, data flow, domain models, or failure envelopes.

2. **Not creating `research/`.** A dedicated research workspace can feel attractive, especially for long surveys. I would resist it because “research” spans the same immutable evidence/current synthesis/experiment split already represented elsewhere.

3. **Allowing light plans in tasks before OpenSpec.** This relaxes the present rule that every implementation plan immediately becomes a change folder. The sharper boundary is: tasks capture intent; OpenSpec captures designed behavior. That makes mid-task filing substantially more mechanical.
