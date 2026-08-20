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

- tier1: exact repo-relative changed path quoted in a truth doc.
  Deletes and renames are the prime candidates.
- tier2: backticked identifier-shaped token (snake_case, CamelCase,
  `call()`, extension-bearing) in a truth doc that also appears in the
  branch's diff hunks.
- tier3 (`semantic`): embedding hits from verbatim-text queries —
  default one per class/section (its docstrings concatenated),
  escalating to one per individual docstring when section results are
  weak (measured: per-section 75% top-3 recall, per-docstring 100%;
  whole-file concat dilutes on mixed-concern files). Searched over the
  current-truth index only. Requires `.lenore/embeddings/`; skipped
  silently without it.

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
apply that directly (additive edit, no user approval needed). Never a
finding.

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
