# 07 — Final adopted design (2026-08-20)

What shipped in plugin v0.5.0 after shrek accepted the full synthesis +
workflow-fit revisions ("I accept all your suggestions. Proceed with
implementation."). Differences from 05-synthesis are marked ◆ (driven by
the 06 workflow-fit review) or ● (driven by shrek's direct answers).

## The docs/ layout (closed, hook-enforced)

```
docs/
  CLAUDE.md                 formatting details (AGENTS.md symlink beside it)
  system.md                 SPINE hub: how it works now — one-page map
  system/                   chapters: architecture / data-flow / state-transitions /
                            premises.md + earned; figures + editable sources beside
  caveats.md                SPINE: where it fails now — stable C<n> IDs + Validity ladders
  playbook.md               SPINE: procedures · tools (use-when + last-verified) ·
                            adopted research conclusions · retired-candidates registry
  proposals/                YYYY-MM-DD-topic.md — the ONE revisable dated class;
                            status: front-matter (hook-checked) + mandatory task pointer
  notes/                    dated immutable; research- naming convention; dated
                            bundle DIRS (index.md + non-own-prose members)
  journal/  bugs/  tasks/  desk/    unchanged
```

- ● **`system`, not `model`** — "model" collides with ML models in these
  repos. Spine = system / caveats / playbook.
- **`docs/reference/` retired** — tools/procedures → playbook; internal
  explanations → system chapters; setup migrates per file.
- **Closed set is hook-enforced** (pre-commit check 3): unknown top-level
  docs/ children rejected with routing help; per-area extension rules
  (◆ diagram sources `.d2/.excalidraw/.mmd/.py` legal beside spine
  chapters and in bundles; `.csv/.json` only in bundles); 5MB/file cap
  under docs/ and experiments/.

## Premises (◆ rank-2 finding of the workflow-fit review)

`docs/system/premises.md` — numbered `**P<n>**` ground rules with
provenance + consumers, admission test "still true if we rewrote the
pipeline in another language tomorrow?". Mandatory pre-design read via a
root-CLAUDE.md rule (cite P-IDs the design rests on or bends). Soft cap
~15 (status line). A chapter with special standing, not a fourth spine
file.

## Caveats shape (◆ adopted from shrek's own E4 practice)

Stable sequential IDs, never renumbered. Required **Validity ladder** per
entry, read in order: `Confirmed:` → `Mechanism:` → `Retracted:` — built
for beliefs that reverse three times in 28 hours.

## Proposals (◆ rank-1 finding; ● named `proposals/` to match shrek's habit)

Dated, **revisable** (plan, not record), front-matter
`status: proposed|accepted|deferred|superseded|implemented` hook-required.
Two-part artifact: `lenore-docs.py proposal` creates file + project.md
pointer atomically; doc-status flags unpointed proposed/deferred ones.
accepted → openspec change (proposal freezes); implemented → conclusions
land in the spine.

## Research (● "research", never "survey"; ◆ bundles legalized)

- Naming: `notes/YYYY-MM-DD-research-<topic>.md` (`note --research`).
- Lifecycle: dated evidence (immutable note) → empirical validation
  (experiment) → adopted conclusion (playbook/system + pointer back).
- ● **Bundle criterion** (checkable version of "tasks with multiple
  outputs"): a note may be a dated DIR only when members are *not prose
  authored by the filing agent* — downloaded sources, data, figures,
  other agents' reports. index.md hook-required; members immutable at
  commit; live progress files legal until the closing commit.
- ● **Papers**: never committed — bytes to `data/library/<topic>/`
  (store), listed in a research note (title/URL/why/store path).

## Candidate systems (◆ §4 of the review; ● ssot: field dropped)

`kind: candidate-system` on the experiment README. Exempt: dated name,
runNNN, store trio. Required: document-map README section, Dead ends &
ruled out register, terminal verdict — adopted (docs copied to
docs/system/ + PROMOTIONS line) / retired (playbook registry line + git
tag) / parked (status flip + unpark condition). Gate-checked like any
conclusion (adopted/retired need verdict + date + journal entry). Core
docs stay INSIDE the candidate dir until adoption.

## Experiments — additions

- README section `Dead ends & ruled out` replaces "What didn't work"
  (◆ adopted from simple-pipeline's register, made REQUIRED once anything
  is ruled out).
- ◆ `figures/` — committed curated human-reviewed images (5MB cap), raw
  outputs stay in the store (resolves shrek's "make sure these images are
  in the experiment dir" vs gitignore conflict).
- `artifact:` front-matter field (README + proposals) + `published: <url>`
  comment for HTML; ◆ doc-status flags committed HTML with no recorded
  URL ("today the only record the artifact exists is this jsonl").

## Retrieval / status surface

- Recall wired into the CLI: `proposal` and `experiment` end by running
  docs-search.py on the title/question and printing top-5 hits in their
  own stdout (grep hint when no index) — tool-output nudge, no memory.
- ◆ Status surface stays computed: browse.py grew spine + proposals
  groups (proposals show `status:`), bundle rows, candidate `kind` in
  experiment extras. No hand-maintained index returns.
- doc-status adds: proposals-open / proposals-unpointed, system-chapters
  soft cap 8, premises soft cap 15, html-no-url.

## Enforcement delta (pre-commit)

Check 3 rewritten (closed layout + extensions + size cap + bundle
index.md); check 5 skips non-index bundle members; check 6 gate extended
to adopted/retired; new check 12 (proposal status field). 22 live tests
green (T1–T15, M1–M3, C1–C3): layout rejections, bundle index
requirement, proposal shape, size cap, candidate gate, proposal
revisability vs bundle immutability, CLI round-trips through the hook.

## Superseded settled decisions

- "No standing ARCHITECTURE.md" → architecture now lives in
  docs/system/ chapters (living, hook-limited, falsifying-commit rule).
- "docs/reference/ for external things" → retired into playbook/system.
- "Every designed plan is an openspec change" → proposals/ holds
  designed-but-not-committed work; openspec holds accepted work.

## Correction (2026-08-20, same day, user)

The shipped C\<n\> caveat IDs and P\<n\> premise numbering violated the
system's own oldest rule ("prose has no addresses") and were removed the
same day: "No designated numbered or other ID based designations. Not
allowed anywhere in the entire generated docs" — an ID scheme is the ADR
latch pattern; agents number, renumber, police, and cross-reference by
ID. Replacement: entries are **named, never numbered** — short
descriptive slug headings (`## seam-drift-at-low-overlap`,
`**operator-wears-gloves — ...**`), cited by name in plain words. The
Validity ladder and the mandatory pre-design premises read survive
unchanged; only the addressing scheme died.
