Re-ran masked NCC at window 64 on the same clip set after the correlation fix.
Command: uv run src/align.py --mask --window 64 --clips data/clips
Code commit: 9d100fc. Dataset: data/clips (12 clips, manifest data/clips/manifest.json).
Result: mean error 7.9px masked vs 5.8px unmasked on the same clip set —
masked NCC is now WORSE than the baseline it was lifted over.
Interpretation: the correlation fix removed the artifact that masking was
compensating for; the production verdict no longer holds.
