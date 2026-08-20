# Reverse-drift check — the shared contract

The landing-time check that changed CODE has not falsified existing
current-truth docs (the reverse of the landing doc review, which checks
the branch's new DOC writing). One contract, two consumers: the
`code-doc-sync-reviewer` agent (Claude, land step 4b) and the Codex
landing flow (which runs the same script and applies these rules
in-session). Verdicts differ between models; candidates, evidence
requirements, caps, and waiver semantics must not.

## The current-truth set

Exactly what `scripts/truth-candidates.sh` scans (single definition —
the script is authoritative): `docs/system.md` + `docs/system/`,
`docs/caveats(.md|/)`, `docs/playbook(.md|/)`, `openspec/specs/**`,
`experiments/*/README.md`. NOT journal, notes, tasks, bugs, or
proposals (dated or disposable, not current truth), NOT
`openspec/changes/` (plans — reconciled by land step 1, not here).

## Candidates

- tier1: changed path quoted in a truth doc — full repo-relative path
  or bare basename when the name is distinctive (identifier-shaped or
  ≥8-char stem; `main.py` never matches). Deletes and renames are the
  prime candidates.
- tier2: backticked identifier-shaped token (snake_case, CamelCase,
  `call()`, extension-bearing) in a truth doc that also appears in the
  branch's diff hunks.
- tier3 (`semantic`): embedding hits, two query kinds per changed
  file, both run unconditionally — (1) one query per individual
  docstring (measured: 100% top-3 recall vs 75% for per-section
  concat, and the whole per-docstring premium on the heaviest files
  was under 7 seconds — no escalation logic, per-docstring IS the
  default; whole-file concat dilutes on mixed-concern files and is
  used only for files with no docstring structure), and (2) one
  HyDE sentence — the reviewer writes 1–3 sentences of "what a design
  doc covering this file's concern would say" and embeds that
  (measured: one extra top-3 rescue at the cost of a sentence; it
  bridges the mechanics-vs-concern vocabulary gap). A file's result is
  its best rank across all its queries. Searched over the
  current-truth index only. Requires `.lenore/embeddings/`; skipped
  silently without it. Evaluated and rejected (measured, kept out
  deliberately): BM25 as a separate index (tier1's basename channel
  already catches every literal-mention case deterministically),
  RRF/score fusion (demoted a correct rank-1 answer to rank 3),
  doc-level score summing (zero aggregate gain, two regressions).

Candidates are read-prompts. A mention is never evidence of drift.
Caps: 50 reviewed candidates, 20 findings. Overflow is NAMED, never
silently dropped — `/doc-health` inherits the named overflow. Churn
damping: a target mentioned by more than ~8 truth docs collapses to
one verify-once line.

## Verdicts and the evidence bar

- `clear` — claim still holds, or the branch already updated the doc.
- `inconclusive` — contradiction not establishable from the code; never
  gates, never nags.
- `finding` — requires ALL FOUR: doc file:line, the claim quoted
  verbatim, the code file:line at branch head, the contradiction stated
  in one sentence. Anything less is `inconclusive`. False positives are
  worse than misses.

## Gating — armed from the first landing

A `finding` blocks the landing, warn-once: fix the doc in the landing
(same commit style as the branch), or waive it — a waiver names the
claim, the evidence, and the reason, and is recorded in the closing
journal entry. An unchanged retry proceeds. `clear`, `inconclusive`,
and coverage-gap recommendations never gate.

## Coverage gaps (per changed file, non-gating)

A changed file whose embedding queries (after per-docstring
escalation) all come back weak has no living-doc home. No fixed
similarity cutoff — scores are corpus-dependent, and a doc can score
high by discussing the concept without covering the mechanism — so the
reviewer confirms by reading the top hit before flagging. The
recommendation is to add docstrings to that file; the main agent may
apply that directly (additive edit, no user approval needed). Added
docstrings must state the concern first, in design-doc vocabulary,
then the mechanics — mechanics-only docstrings stay invisible to this
very check. Never a finding.

## The sync report

Every landing saves the reviewer's reply verbatim as
`docs/notes/<date>-landing-<slug>-sync-report.md` (dated note,
immutable once committed). It contains the metrics line
(`sync-check: candidates N (t1/t2/t3), findings F, coverage-gaps G,
overflow O`), per-candidate verdicts, findings with evidence, waivers,
coverage-gap recommendations, and the named overflow. These notes are
the trend record: revisit the caps after two landings — regular
overflow → raise the candidate cap; findings always in the top handful
→ lower it; frequent waived-as-false findings → raise the evidence
bar, not the cap.
