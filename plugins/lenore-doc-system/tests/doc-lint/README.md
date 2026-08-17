# doc-lint judgment suite

Regression suite for the `doc-lint-judge` agent prompt (`agents/
doc-lint-judge.md`) as exercised through `templates/scripts/doc-lint.sh`.
Run it before shipping ANY change to the judge prompt or the lint script:

```
tests/doc-lint/run-suite.sh        # ~17 Haiku calls, ~2 min
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
