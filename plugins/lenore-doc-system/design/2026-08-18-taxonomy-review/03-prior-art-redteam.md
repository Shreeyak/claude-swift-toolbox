The existing Lenore design has the right foundational distinction—records versus current truth—but draws current truth too narrowly. In particular, treating architecture as an on-demand dated snapshot guarantees that the repository has no dependable answer to “how does this system work now?”

I would preserve immutable capture, replace `docs/reference/` with three fixed living documents, and classify by the reader’s question rather than by knowledge type:

- `model.md`: What is this system and how does it work?
- `caveats.md`: Where does that model fail or mislead?
- `playbook.md`: How do we repeatedly work with it?

No ADRs, decision log, or disguised equivalent.

## Part A — Prior art and its load-bearing lesson

### Diátaxis

Diátaxis separates explanation, which supports understanding and answers “why?”, from reference, which supplies neutral facts needed while working. It explicitly says reference structure should resemble the thing described. [Diátaxis overview](https://diataxis.fr/), [five-minute guide](https://www.diataxis.fr/start-here/).

For the requested material:

| Material | Predominant Diátaxis form |
|---|---|
| Architecture and data-flow narrative | Explanation |
| State-transition table | Reference |
| Domain model | Explanation |
| Glossary and exact concept definitions | Reference |
| Failure-mode registry | Reference |
| Explanation of why failures occur | Explanation |
| Statistical pattern or interpretation | Explanation |
| Exact data anomaly, affected range, caveat | Reference |
| Tool shortlist | Reference |
| “When should I use this tool?” | Explanation or how-to |
| Literature synthesis | Explanation |
| Bibliography/source metadata | Reference |
| Plans | Neither; working/project-management material |

Load-bearing lesson: explanation and reference are writing modes, not necessarily directory names. In a solo repository, splitting every mixed subject into parallel “explanation” and “reference” trees would create more navigation and synchronization work than value.

### Scientific laboratory practice

Scientific practice distinguishes:

- The dated laboratory notebook: permanent evidence of what was attempted, observed, and inferred.
- The controlled protocol or methodology notebook: the current repeatable procedure.
- The review article: retrospective synthesis across many observations and papers.

NIH guidance expects dated, reconstructable records and immutable audit history, while methodology documentation standardizes procedures reused across experiments. Modern laboratory-information guidance explicitly recommends that notebook entries hold context, results, and interpretation while pointing to versioned protocols and datasets. [NIH electronic lab-notebook policy](https://oir.nih.gov/sourcebook/intramural-program-oversight/electronic-lab-notebooks/intramural-electronic-lab-notebook-policy), [research-record guidance](https://www.ncbi.nlm.nih.gov/books/NBK236192/), [laboratory information guidance](https://pmc.ncbi.nlm.nih.gov/articles/PMC10703290/).

Load-bearing lesson: discovery and truth are different products. “Observed 7% nulls today” belongs in an immutable record; “releases before v3 contain unreliable geographic fields” belongs in a maintained caveat; the reusable cleaning procedure belongs in a playbook.

### Zettelkasten and evergreen notes

Luhmann’s slip box was a thinking instrument organized around relationships rather than a subject filing cabinet. Later Zettelkasten practice distinguishes fleeting capture, source/literature notes, and self-contained permanent notes. [Luhmann archive](https://niklas-luhmann-archiv.de/nachlass/zettelkasten), [capture-to-permanent overview](https://zettelkasten.de/posts/concepts-sohnke-ahrens-explained/).

Its common failure is processing debt: people collect sources and fleeting notes faster than they can distill them, mistake possession for understanding, and eventually abandon an intimidating inbox. Even experienced practitioners describe years of unprocessed notes—the “collector’s fallacy.” [Collector’s Fallacy account](https://zettelkasten.de/posts/collectors-fallacy-confession/).

Load-bearing lesson: retain atomic, low-friction capture, but reject mandatory “process every note” workflows. Distillation should be demand-driven: promote knowledge when it becomes current, reusable, or repeatedly searched—not because an inbox exists.

### Engineering wikis and wiki rot

Wikis lower page-creation friction, so they grow organically into duplicate pages, competing terminology, oversized pages, orphan pages, and structures requiring continual “gardening.” Research on wiki maintenance calls that gardening tedious and error-prone and describes continuous structural degradation at scale. [Dohrn and Riehle, *Design and Implementation of Wiki Content Transformations and Refactorings*](https://dirkriehle.com/wp-content/uploads/2013/06/wiki-transformations-final.pdf).

The famous organizational failure is not merely stale prose; it is ambiguous authority. Search returns five plausible pages, nobody knows which is current, and creating a sixth page is easier than reconciling the first five.

Load-bearing lesson: agents must not have wiki-style page-creation freedom in the living layer. Fix the number of living files; permit unlimited dated evidence underneath them.

### Hardware errata and dataset known-issue registries

Intel specification updates distinguish product errata from specification changes, clarifications, and documentation corrections. Errata carry affected revisions and statuses such as “fix,” “fixed,” and “no fix”; they remain visible through the product lifecycle rather than being treated as an ordinary engineering backlog. [Intel Quark specification update](https://cdrdv2-public.intel.com/332911/quark-d1000-spec-update.pdf).

Dataset publishers similarly document the affected data, known effect, cause where known, corrective action, and usage warning. The US Census Bureau requires public notification even before an issue is fully understood and subsequent updates as understanding improves. [Census Statistical Quality Standard F1](https://www.census.gov/about/policies/quality/standards/standardf1.html), [ASPEP user notes](https://www.census.gov/programs-surveys/apes/technical-documentation/user-notes.html).

Load-bearing lesson: a failure-mode registry is not a bug list. It is current consumer-facing truth about scope, effect, detection, and mitigation; entries may legitimately remain “no fix.”

### Glossaries

Mature terminology guides treat glossaries as controlled reference: use one unambiguous term consistently, define unfamiliar terms, and record preferred or prohibited alternatives. Google recommends collecting definitions into a glossary when many terms are introduced and maintains a preferred word list for consistency. [Google technical-writing guidance](https://developers.google.com/tech-writing/one/words), [Google word list](https://developers.google.com/style/word-list).

Load-bearing lesson: exact terms deserve a lookup surface, but a standalone `concepts.md` tends to become disconnected mini-essays. Keep the glossary inside the current system/domain model, adjacent to the mechanisms that use those words.

### Awesome lists and tool compendia

The Awesome manifesto’s defining rule is that an awesome list is “curation, not a collection”: include only things someone can recommend, explain why they belong, and keep scope narrow. Mature lists add activity and maintenance requirements because every entry creates continuing verification work. [Awesome manifesto](https://github.com/sindresorhus/awesome/blob/main/awesome.md), [Awesome Go contribution standards](https://github.com/avelino/awesome-go/blob/main/CONTRIBUTING.md).

Load-bearing lesson: “discovered tools” should be captured freely in dated notes, but the living playbook should contain only evaluated tools with a specific use case. A bookmark dump is cheaper to recreate with search than to maintain.

### Solo-developer and indie practice

Solo practice benefits from small, searchable, repository-local records more than from ownership matrices, review councils, content calendars, or documentation portals. Simon Willison’s repository-backed TIL collection is a concrete example: hundreds of dated, narrowly scoped discoveries remain useful without pretending that each is current project truth. [Simon Willison’s TIL collection](https://til.simonwillison.net/), [his explanation of the format](https://simonwillison.net/2022/Nov/6/what-to-blog-about/).

Load-bearing lesson: organizational documentation systems optimize coordination among people; this system must optimize memory across time and agent sessions. Cheap capture plus a tiny curated current surface beats comprehensive governance.

## Part B — Red team of the obvious `docs/reference/` expansion

### 1. Five concrete boundary disputes

1. **“OAuth refresh occasionally races after a laptop wakes.”**

   This could be a bug, an application failure mode, an external API quirk, or a dated investigation note. Route by lifecycle: evidence in a note; repairable work in `bugs/`; a user/operator-visible current hazard in `caveats.md`.

2. **A state diagram inferred from production traces.**

   It begins as dated analysis, could become architecture explanation, and may overlap a feature specification. The trace interpretation belongs in a note; the presently believed cross-system model belongs in `model.md`; exact feature guarantees remain in the spec.

3. **“Geographic code is absent in 7.2% of records before dataset v3.”**

   It may be a data insight, anomaly, upstream failure, ingestion bug, or experiment finding. Preserve the measurement in the experiment/notebook or note; put the active usage warning in `caveats.md`; file a bug only if the repository violates its own ingestion contract.

4. **A paper recommends a similarity threshold of 0.83.**

   This could be literature research, domain knowledge, an experiment hypothesis, or current configuration documentation. The reading goes in a dated note; testing goes in an experiment; only a validated, adopted conclusion reaches `model.md` or `playbook.md`.

5. **A newly found CLI can inspect corrupted media containers.**

   It could be a tool entry, research note, troubleshooting procedure, task, or implementation dependency. Capture it in a note immediately; promote it to `playbook.md` only after use; add a task only when adoption is actually intended.

The problem with `reference/failure-modes.md`, `concepts.md`, `tools.md`, and arbitrary domain topics is that the nouns describe content but not authority, maturity, or action.

### 2. The junk-drawer gradient

`tools.md` becomes the first dumping ground because adding a link feels harmless and requires no claim of truth. It accumulates “maybe useful,” alternatives already rejected, dead links, and tools no agent has actually run.

Next is `concepts.md`. Anything vaguely explanatory can be called a concept, so it grows into an unstructured mixture of glossary, architecture, literature notes, product ideas, and terminology debates.

Finally, `failure-modes.md` becomes a shadow backlog when agents re-label every unresolved bug as a “known limitation.” Then `docs/bugs/` stops being the authoritative live repair list.

`docs/reference/` itself eventually means “important prose that did not fit elsewhere”—the definition of a junk drawer.

### 3. Capture versus distillation

These need append-only capture:

- Raw literature reading and quotations
- Architecture hypotheses
- Newly observed failure symptoms
- Data measurements and anomalies
- Tool discoveries and first-use impressions
- Comparisons and rejected approaches
- Experiment runs and interpretations

These need curated living form:

- Present architecture, flows, and state model
- Canonical domain vocabulary
- Currently applicable failure modes and data caveats
- Accepted operating procedures
- Evaluated tool recommendations
- Literature conclusions the project currently relies upon

Many items need both. Capture records why the conclusion was reasonable; the living version tells the next agent what to believe now.

If only immutable capture exists, search returns an archaeological pile of mutually inconsistent claims and every session must redistill the answer. If only living documents exist, agents prematurely overwrite uncertainty, erase provenance, and silently turn one observation into doctrine.

### 4. The N+1 problem

The likely next requests are:

- Security assumptions
- Performance budgets
- Compatibility constraints
- Operational runbooks
- UX heuristics
- Dependency policies
- Privacy or compliance knowledge

A content-type taxonomy responds with six new files or directories. The proposed question-based model absorbs them:

- “What is true and how does it work?” → `model.md`
- “Where is it unsafe, unreliable, or conditional?” → `caveats.md`
- “How do we repeatedly do this?” → `playbook.md`
- “What happened or what did we observe?” → dated note/experiment
- “What should happen later?” → task/change

If a future type cannot answer one of those questions, it probably is not repository knowledge.

### 5. Twenty-session agent-sprawl attack

| Attack | After 20 sessions | Hard stop |
|---|---|---|
| File proliferation | `reference/auth/`, `architecture/`, `domain/`, `research/`, `tools/`, each with overlapping pages | Exactly three living prose files; hook rejects a fourth without explicit configuration change |
| Index bloat | README, `INDEX.md`, per-folder indexes, generated TOCs, “maps of content” | No maintained indexes; `ls`, grep, and `browse.py` are the index |
| Tag invention | `status`, `confidence`, `topic`, `kind`, `owner`, `review-by`, arbitrary hashtags | No tags or front matter in ordinary docs; only existing machine-required experiment fields |
| Subdirectory invention | Agents create ever-finer “clean” hierarchies | No subdirectories under the living layer; no subdirectories under notes/journal |
| Duplicate living truth | Architecture repeated in model, spec, CLAUDE, and integration pages | `model.md` describes cross-cutting understanding; specs own exact feature contracts; CLAUDE owns agent rules/invariants |
| Tool hoarding | Hundreds of untested links | Playbook admits only locally evaluated tools with a stated use; hard entry/file cap |
| Shadow backlog | Caveats acquire “TODO/fix later” entries | Repair intent routes to `bugs/` or `tasks/`; caveats state present effect and mitigation, not future work |
| Compulsory distillation | Growing “unprocessed notes” counter creates permanent chores | No inbox, promotion queue, or requirement to process every note |
| Tiny-file enthusiasm | One permanent file per term, paper, anomaly, component | Unlimited small files only in immutable capture; living truth stays consolidated |
| Premature certainty | One observation overwrites current truth | Living claims require a code/spec anchor, experiment/run, dataset query, or dated note as evidence |

## Part C — The design I would ship

```text
CLAUDE.md                         agent rules, commands, durable invariants

openspec/
  specs/                          exact as-built feature contracts
  changes/                        substantial in-flight implementation plans

docs/
  model.md                        what the product/domain is and how it works now
  caveats.md                      current failure modes, limits, and data hazards
  playbook.md                     repeatable procedures and evaluated resources

  journal/
    YYYY-MM-DD-HHMM-topic.md      immutable project narrative

  notes/
    YYYY-MM-DD-topic.md           universal immutable capture

  bugs/
    YYYY-MM-DD-topic.md           repairable defects awaiting fixes

  tasks/
    project.md                    small queue of light future intentions
    branch-<name>.md              disposable branch/session memory

  desk/                           3–8 human-facing symlinks, never originals

experiments/
  YYYY-MM-DD-name/
    README.md                     current experiment conclusion
    notebook/                     immutable run evidence
    ...

tmp/                              uncommitted throwaway work
```

The rules for the three new living files are:

- `model.md`: Current shared model of the domain and system—canonical terms, architecture, components, data flows, state transitions, and important causal explanations.
- `caveats.md`: Conditions under which the model, application, or data becomes unreliable—each entry states scope, effect, detection, mitigation, and evidence.
- `playbook.md`: Procedures and external knowledge actually reused—how-tos, protocols, evaluated tools, and literature-backed working guidance, never raw research or bookmarks.

### The ten-second routing rule

1. Is it merely observed, investigated, read, or uncertain? Put it in a dated note immediately.
2. Is it exact feature behavior enforced with code? Put it in the relevant spec.
3. Is it the current cross-cutting model? Update `model.md`.
4. Is it a current hazard or limitation somebody must account for? Update `caveats.md`.
5. Is it a repeatable way of working? Update `playbook.md`.
6. Is it intended repair work? File a bug.
7. Is it intended future work but not a defect? Add one task line.
8. Still unsure after ten seconds? Write the dated note and stop categorizing.

That final escape hatch is essential: misfiled immutable evidence is recoverable through search; uncaptured evidence is gone.

### Hard limits

- Exactly three general-purpose living documents under `docs/`: `model.md`, `caveats.md`, and `playbook.md`.
- No `docs/reference/`, `docs/knowledge/`, `docs/research/`, `docs/concepts/`, `docs/tools/`, or living-topic subdirectories.
- No new living document without explicit human approval and a demonstrated inability to place three real examples in the existing files.
- Each living file has a 500-line ceiling. At the ceiling, agents consolidate or remove obsolete living material; they do not split automatically.
- Heading depth stops at `###`. No tag systems, IDs, knowledge graphs, status vocabularies, or hand-maintained indexes.
- `caveats.md` entries are at most 20 lines and must cover scope, effect, detection, mitigation, and an evidence pointer. A naked symptom is a bug or note, not a caveat.
- `playbook.md` contains at most 30 named tools/resources. Each requires “use when,” local experience or evidence, and a last-verified date. Discovery alone never qualifies.
- `docs/tasks/project.md` contains at most 15 items total. Longer context becomes a dated note; substantial implementation planning becomes an OpenSpec change.
- The desk remains between 3 and 8 pins.
- Dated notes have no processing status. There is no “unprocessed,” “evergreen,” “promote,” or “review by” field.
- Promotion is demand-driven: update a living file when implementing, answering a current-truth question, or encountering the same knowledge a second time.
- Hooks should enforce shape and prohibited paths, not judge semantic taxonomy beyond these few mechanical rules.

### Where I disagree with conventional tidy taxonomy

I would intentionally put glossary terms, architecture explanation, data-flow diagrams, and state-transition tables in the same `model.md`. Diátaxis would recognize different writing modes inside it, but the solo developer’s retrieval question is the same: “How does this thing work?”

I would also combine application failure modes and data anomalies in `caveats.md`. They differ ontologically, but they impose the same obligation on a consumer: know the affected scope, recognize the condition, and avoid a wrong result.

Finally, I would not create a permanent “literature” or “tools” collection. Raw encounters belong in dated notes; only conclusions that change the project’s model or practice deserve scarce space in the living layer. That scarcity is a feature: it makes the current documents authoritative precisely because agents cannot create another shelf whenever filing feels uncomfortable.
