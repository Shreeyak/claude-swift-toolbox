# run006-post-correlation-fix — 2026-08-14
After the correlation fix, masked NCC is WORSE than the unmasked baseline (7.9px vs 5.8px).

command: uv run align.py --mask --window 64 --clips data/keep/clips
commit:  9d100fc
inputs:  data/keep/clips (12 clips, manifest data/keep/clips/manifest.json)
outputs: data/out/run006-post-correlation-fix/

## What happened
Re-ran masked NCC at window 64 on the same clip set after the correlation
fix. Mean error 7.9px masked vs 5.8px unmasked on the same clip set —
masked NCC is now worse than the baseline it was promoted over.

## Interpretation
The correlation fix removed the artifact that masking was compensating
for; the production verdict no longer holds.
