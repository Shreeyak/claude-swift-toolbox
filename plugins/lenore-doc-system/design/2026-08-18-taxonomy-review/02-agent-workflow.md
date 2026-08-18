The workflow should optimize for three facts about coding agents:

- They read `CLAUDE.md`, the active task, and files adjacent to the code they are changing.
- They have strong recency bias and rarely browse “just in case.”
- Append-only capture is reliable; voluntary maintenance of detached living documents is not.

Therefore, knowledge that must influence implementation needs to live with current truth or be linked from it. Dated notes are excellent evidence and memory, but poor operational instructions.

## 1. Read versus write cadence

“Regularly” below means during every relevant subsystem task—not reading the whole corpus at every session start.

| Knowledge type | Best home | When agents read it | When agents update it | Read regularly? | Update regularly? |
|---|---|---|---|---:|---:|
| Core behavior: data flow, state transitions, invariants | Relevant `openspec/specs/`; only cross-cutting invariants in `CLAUDE.md` | Before changing that subsystem, designing across it, or debugging behavior spanning components | In the same commit that changes the described behavior | Yes | Yes |
| App failure modes | `## Failure modes and recovery` in the relevant spec; unresolved defects in `docs/bugs/`; investigations in dated notes | Before changing error handling, retries, recovery, boundaries, or debugging a matching symptom | When a new supported failure mode is established or recovery behavior changes; delete bug file with its fix | Yes | Yes |
| Domain knowledge | Small living `docs/reference/domain-<topic>.md`; implementation-critical rules duplicated as concise spec invariants | Before encoding policy, interpreting domain terms, or designing domain behavior | After verified research changes the working model or a repeated misunderstanding appears | Yes, when in domain code | Triggered |
| Data insights and anomalies | Run evidence in experiment notebook; synthesized truth in experiment README; production data contracts in specs; unvalidated observations in dated notes | Before data-dependent changes, experiments, threshold changes, or anomaly debugging | Notebook immediately after inspecting a meaningful run; README after a material synthesis change—never more than two runs behind | Yes, when data-related | Yes during investigation |
| Concept compendium | One small living `docs/reference/concepts.md`, with critical terms summarized in `CLAUDE.md` and pointers to authoritative specs | When unfamiliar vocabulary appears; before inventing a new term | When term meaning changes or the same vocabulary correction happens twice | Lookup-driven | Low but necessary |
| Discovered tools | `docs/reference/tool-<name>.md` only when repeated use is likely; internal scripts describe themselves in their header | Immediately before using/configuring the tool, or when its setup fails | After verifying a changed invocation, integration quirk, or API behavior | No | Triggered |
| Literature research | Living topic synthesis in `docs/reference/literature-<topic>.md`; dated note for a one-time paper reading or research snapshot | Before a design relying on outside evidence or when reopening the research question | At the end of a substantive research pass, if the synthesis changed | No | Post-research |
| Light plans | Active `docs/tasks/branch-<name>.md`; future queue in `project.md`; implementation plans in `openspec/changes/` | Active branch task at session start; project queue at landing/planning; change folder while implementing | As the immediate plan changes; reconcile at landing | Yes | Yes |

A normal SessionStart should read only:

1. Root `CLAUDE.md`.
2. The active branch task and active OpenSpec change.
3. The status line.

It should not automatically read journal, notes, literature, tool references, or every spec.

The distinction between the two kinds of rot matters:

- **Rots if not read:** core specs, failure modes, domain rules, data findings, concepts, and active plans. Their content may be correct but operationally useless if agents never encounter it.
- **Rots if not updated:** specs, experiment READMEs, domain references, concept definitions, tool references, literature syntheses, and task files.
- **Does not semantically rot:** dated notes, journal entries, and experiment notebook entries. They age as evidence. Their retrieval value can decay, but they should not be “maintained.”

The current ban on a standing `ARCHITECTURE.md` is sound. But current data flows and state transitions cannot be relegated entirely to dated snapshots if agents depend on them. Put behavioral portions into the applicable specs; retain architecture notes only as dated cross-sectional explanations.

## 2. Filing decision procedure

Use this four-step decision tree. It should take less than a minute for ordinary discoveries.

1. **Is this current behavior agents must implement against?**  
   Put it in the relevant spec. Use `CLAUDE.md` only for truly cross-cutting invariants. If it is an experiment’s present conclusion, update that experiment’s README.

2. **Is it a violated expectation that should be fixed?**  
   File a bug with symptom and repro. An expected limitation, degraded mode, or operational hazard is a failure mode in the spec—not a bug.

3. **Is it evidence rather than current truth?**  
   Experiment result → run notebook. Otherwise → dated note. An unconfirmed anomaly defaults here until it is understood.

4. **Is it repeatedly reusable external knowledge?**  
   Update or create a living `domain-`, `tool-`, `literature-`, or the single `concepts.md` reference. Mere discovery is not enough; require a concrete expected reuse.

After that, two orthogonal actions may apply:

- If it creates future work, add a short task pointer.
- If it changes project direction or closes a milestone, write the short journal entry.

Do not copy the full discovery into the task and journal; those should point or summarize.

Misfilings will concentrate around:

- Expected failure mode versus fixable bug.
- Unconfirmed anomaly versus durable data contract.
- Dated research evidence versus living synthesis.
- Tool merely encountered versus tool worth maintaining.
- Architecture snapshot versus current behavioral specification.
- Light future intention versus implementation-ready OpenSpec change.

The cheapest correction loop is a **write-time nudge in `lenore-docs.py`**, not a periodic refiling pass. For example, a proposed `capture` command could ask one compact question: “current truth, defect, evidence, or reusable external reference?” Then route accordingly.

Periodic refiling conflicts with committed-note immutability and becomes librarian ceremony. Commit-time semantic lint is also too late and too subjective. Keep lint for structural violations; use the CLI nudge for routing. When uncertain, a dated note is the safest temporary classification because it makes no claim of current authority.

## 3. Retrieval without RAG

Use one compact routing map, computed listings, and explicit task triggers.

### The retrieval sequence for problem P

1. **Route by intent.**
   - “What is true?” → spec, `CLAUDE.md`, experiment README.
   - “What is broken?” → bugs.
   - “What did we learn or try?” → notes, journal, experiment notebooks.
   - “How do I use this external thing?” → reference.
   - “What am I doing?” → tasks and active change.

2. **Search exact anchors first.**  
   Grep for subsystem names, error strings, paths, flags, dataset names, parameters, and identifiers.

3. **Use semantic search for conceptual recall.**  
   Before design, a new experiment, or guessing an unfamiliar term, query one concept at a time and open the top one to three files.

4. **Resolve authority before acting.**  
   A dated hit is evidence. A current spec or experiment README wins if they disagree. Re-find all exact numbers with grep.

### Indexing choices

- **Per-type index files:** reject. Agents will not update them reliably.
- **One manually maintained map file:** also reject. The root `CLAUDE.md` should contain only the small question-to-home table and search triggers.
- **Computed map:** use `browse.py --plain`; this is the actual index.
- **Frontmatter tags:** avoid outside experiment lifecycle metadata. Agents invent synonyms, omit tags, and stop trusting the taxonomy.
- **Naming conventions:** useful and cheap. Use domain nouns and subsystem vocabulary:
  - `domain-payments.md`
  - `tool-ferry.md`
  - `literature-image-registration.md`
  - `2026-08-18-ghosting-at-low-overlap.md`

Do not duplicate the directory class in dated-note filenames unless it improves the likely search phrase.

The existing top-level `research/` directory is effectively invisible: `browse.py` and `docs-search.py` search `docs/`, experiments, and OpenSpec, not arbitrary `research/` content. Either move it into dated notes/living literature references or deliberately add it to both tools. Moving it is simpler and preserves the closed layout.

### Making semantic search happen

A static “semantic search is available” line will be ignored. The reliable triggers are actions:

- Put the search rule directly in root `CLAUDE.md`: before proposal/design, new experiment, or guessing unfamiliar vocabulary.
- Have experiment creation automatically run or prominently offer a search using the experiment question.
- Have the OpenSpec proposal workflow run the same recall step.
- Provide one command that gracefully uses embeddings when available and falls back to grep plus `browse.py` when unavailable.

The SessionStart status should report index health, but it should not tell agents to search on every session. Search must be coupled to designing, experimenting, and vocabulary uncertainty.

## 4. Maintenance and anti-sprawl

Realistically maintained:

- Active branch tasks, because the current session consumes them.
- Bugs, because deletion is coupled to the fix commit.
- Experiment notebooks, because they are part of running experiments.
- Experiment READMEs, if the current contradiction lint and unreflected-run counter remain.
- Specs directly touched by implementation.
- A few reference documents used repeatedly.

Likely to rot silently:

- Broad architecture prose detached from specs.
- Large concept encyclopedias.
- Tool catalogs containing things merely encountered once.
- Paper-by-paper research collections.
- Reference docs for rarely used external systems.
- Plans not attached to an active branch or OpenSpec change.

Recommended hard limits:

- Hook-enforce a closed, flat set of `docs/` children. Reject new homes such as `docs/research/`, `docs/insights/`, `docs/concepts/`, and nested taxonomies.
- Limit the desk to eight links.
- Limit `project.md` Someday to ten items and total deferred items to about twenty.
- Limit living `docs/reference/` to roughly 24 files. Beyond that, update an existing synthesis or write a dated note.
- Permit exactly one general `concepts.md`; domain-specific definitions belong with their domain reference or spec.
- Cap Markdown documents at 64 KiB and living reference documents at roughly 2,500 words. Large evidence belongs in multiple dated notes; large current behavior belongs in scoped specs.
- Preserve the existing journal, bug, and task shape caps.

Do **not** hard-cap:

- Historical note or journal counts.
- Bug count—the system must never discourage filing a real defect.
- Experiment count over the repository’s lifetime.

Use status counters rather than blockers for:

- Exploring experiments, with warning pressure above three.
- Bugs above ten.
- Living references untouched for 90 days.
- Oversized documents.
- Reference count versus its cap.
- Unreflected experiment runs.
- Unknown documentation directories.

This creates pressure on small active surfaces without forcing agents to bundle unrelated history merely to satisfy a number.

## Top 5 concrete recommendations

1. Route current data flows, state transitions, and expected failure modes into the relevant OpenSpec specs; keep dated architecture notes non-authoritative.
2. Eliminate the separate `research/` knowledge silo: use dated notes for evidence and a small set of living `literature-<topic>.md` syntheses for repeated use.
3. Add the four-way write-time routing nudge—current truth, defect, evidence, reusable external reference—to `lenore-docs.py`; do not build a refiling process.
4. Make recall an automatic step of proposal and experiment creation, with semantic search falling back to grep and `browse.py`.
5. Hook-enforce the closed flat layout, desk/task/reference caps, and document size limits; use status counters—not blockers—for historical volume, bugs, and experiment backlog.
