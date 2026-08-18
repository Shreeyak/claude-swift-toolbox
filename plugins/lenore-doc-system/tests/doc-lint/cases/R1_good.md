# run004-window-48 — 2026-08-12
Window 48 is marginally worse than the production 64 (2.3px vs 2.1px); keep 64.

command: uv run align.py --mask --window 48 --clips data/keep/clips
commit:  4be21aa
inputs:  data/keep/clips (12 clips, manifest data/keep/clips/manifest.json)
outputs: data/out/run004-window-48/

## What happened
Re-ran masked NCC at window 48 to check sensitivity of the production
default. Mean error 2.3px masked vs 5.8px unmasked baseline; the per-clip
spread matched run002's within noise.

## Interpretation
Window 48 is marginally worse than the production window 64 (2.3px vs
2.1px) but still far ahead of the unmasked baseline; keep 64 as the
default. Consistent with the README verdict.
