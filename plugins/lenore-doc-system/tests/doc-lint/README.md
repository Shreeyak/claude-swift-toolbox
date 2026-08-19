# doc-lint judgment suite

Regression suite for the `doc-lint-judge` agent prompt (`agents/
doc-lint-judge.md`) as exercised through `templates/scripts/doc-lint.sh`.
Run it before shipping ANY change to the judge prompt or the lint script:

```
tests/doc-lint/run-suite.sh        # ~26 Haiku calls, ~3-4 min
```

Expected verdict is encoded in the filename: `*good*` and `*borderline*`
must PASS, everything else must BLOCK. Exit code = number of mismatches.

## Provenance and baseline

Built 2026-08-17 by a Sonnet tuning agent. Baseline result against the
shipped prompt: **17/17 correct, zero false positives, zero false
negatives.** The six pass-risk cases (J1, N1, B1, T3, T4, T5) were
re-drawn 3× each and held; T1b/T2b are fresh-domain rewrites added after
noticing T1/T2 were near-verbatim to the prompt's own calibration example
(contaminated evidence — keep both pairs).

The R class (experiment notebook entries) was added 2026-08-17 after the
user observed agents landing runs without ever updating the experiment
README's verdict. The runner commits a fixture README
(`experiments/2026-08-01-masked-ncc/`, status: concluded, verdict claiming
masked NCC beats baseline, new-template Findings section) so R cases
exercise the CONTEXT-append path of doc-lint.sh: R1 is a consistent
evidence-grade entry (held PASS across 3 re-draws), R2 is a vibes-only
entry with no command/commit/metrics, R3 is an evidence-grade entry whose
result contradicts the fixture verdict while the README goes untouched —
the verdict-freshness check the class exists for. Baseline with the R
rules added: **20/20**, all pre-existing cases unchanged. 2026-08-18: the
R cases and fixture were rewritten into the notebook-era shapes
(`notebook/` dir, `# runNNN — date` header + outcome line + What
happened/Interpretation sections, README with `question:` front-matter and
Findings) when `runs/` became `notebook/`; the suite was re-run and held
20/20.

The borderline cases encode the design priority: **false positives are
worse than false negatives** for a commit gate. If a prompt change makes
any `borderline_*` case BLOCK, the change is wrong regardless of what
else it improves.

## Known residual weaknesses (signals for future refinement)

- `T4_borderline_short_selfcontained` (zero context lines) and
  `T5_borderline_codename_with_path` pass by generalizing from the rule
  text — they have no dedicated calibration anchor in the prompt. If they
  ever start flapping, add an OK calibration example of each shape rather
  than loosening the rules text.
- The modified-file-already-in-HEAD path of the lint's porcelain grep has
  never been exercised (all cases are new files).
- Single-draw LLM judging: a clean run is one sample. For prompt changes,
  re-draw at least the borderline cases 3× (the baseline did).

The hygiene classes (N5-N8, J5-J6) were added 2026-08-20 with the
doc-hygiene-rules.md rulebook: invented entry IDs vs domain identifiers
(P95/RFC/runNNN must pass), session-opaque codenames vs
defined-at-first-use, reviewer-directed phrases in a journal entry vs
legitimate past-narration (J6 guards the journal's exemption from the
history-narration rule). Baseline after adding: 26/26 correct.
