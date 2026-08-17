Re-ran masked NCC at window 48 to check sensitivity of the production default.
Command: uv run src/align.py --mask --window 48 --clips data/clips
Code commit: 4be21aa. Dataset: data/clips (12 clips, manifest data/clips/manifest.json).
Result: mean error 2.3px masked vs 5.8px unmasked baseline.
Interpretation: window 48 is marginally worse than the production window 64
(2.3px vs 2.1px) but still far ahead of the unmasked baseline; keep 64 as
the default. Consistent with the README verdict.
