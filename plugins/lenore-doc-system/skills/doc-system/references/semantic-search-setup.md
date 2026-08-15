# Semantic search setup (optional)

Read when a repo's docs have outgrown one `browse.py` screen and grep is
missing hits on vocabulary drift ("seam" vs "blend boundary"). Not loaded
by SKILL.md — a working doc system never needs this file; only load it
when actually setting up or troubleshooting `scripts/docs-search.py`.

## When to bother installing at all

Not before. `browse.py` + grep + asking the agent (who reads fast) covers
small and medium repos. Install `docs-search.py` only once a project's
`docs/` + `experiments/*/README.md` + `experiments/*/runs/*.md` corpus is big enough that scanning a
`browse.py` screen no longer finds things — there is no fixed threshold,
it's a "grep keeps missing things" judgment call.

## Prerequisites

- **Apple Silicon Mac.** The script uses MLX, which is Apple-Silicon-only.
  On Intel Macs or Linux/Windows, skip this — see "no Apple Silicon" below.
- **`uv`** installed (`curl -LsSf https://astral.sh/uv/install.sh | sh`).
  The script is a single-file PEP 723 script; `uv run` resolves its
  dependencies (`mlx`, `tokenizers`, `huggingface_hub`, `numpy`) into an
  ephemeral environment on first run — nothing to `pip install` by hand.
- **First run downloads model weights — once per machine, not per repo.**
  `jinaai/jina-embeddings-v5-text-nano-retrieval-mlx` (float16, ~424MB on
  disk) downloads into the shared Hugging Face cache
  (`~/.cache/huggingface/hub`), keyed by model id, not by repo. Every
  Lenore-doc-system repo on the same machine reuses that one cached copy —
  never vendor or copy the weights into a repo, and never point
  `HF_HOME`/the cache dir somewhere repo-local. Run directly in fp16, no
  in-process quantization. See `templates/scripts/docs-search.py`'s header
  comment for exactly what was verified about this model and the package
  used; see the benchmark below for measured latency/memory.
- **Fallback download** if the Hugging Face download is blocked (corporate
  network, rate limit): a mirror of the weights is attached to the
  `claude-swift-toolbox` GitHub release. `gh release download <tag> -p
  'jina-embeddings-v5-text-nano-retrieval-mlx*' -D
  ~/.cache/huggingface/hub/models--jinaai--jina-embeddings-v5-text-nano-retrieval-mlx/snapshots/<rev>/`,
  then run with `HF_HUB_OFFLINE=1` (or load the files as a local dir via
  `snapshot_download(local_dir=...)`) so the script never re-hits the Hub.

## Measured cost (Apple Silicon, M-series, weights already cached)

- Cold process, single query (`uv run scripts/docs-search.py "..."`): ~0.85-0.9s wall, ~700-740MB peak RSS. Dominated by `uv`/Python/MLX/tokenizer startup, not the embedding itself.
- Model load alone (in-process, no `uv`/CLI overhead): ~0.8s.
- Embedding, once the model is loaded: ~4.9ms/doc batched (50 docs in 0.24s on first batch, ~3.1ms/doc / 0.16s on a second warm batch in the same process) — sub-millisecond-scale per query in practice.
- Peak RSS for a 50-doc in-process batch: ~575MB.

Net: per-search cost is dominated by process startup, not the model — fine
for the incremental, one-or-a-few-changed-files-per-session pattern this
script is built for.

## One-time verification

```
uv run scripts/docs-search.py --status
```

Prints the cache directory, how many chunks are indexed (if any), and
whether the model is already in the local HF cache. Run this once after
install to confirm the toolchain resolves before relying on it — if it
hangs or errors, see Troubleshooting below rather than debugging mid-task.

## The cache directory

`.docs-embeddings/` at the repo root (gitignored — see
`templates/gitignore-snippet`):

- `meta.json` — chunk id → `{path, heading, summary}`.
- `vectors.npz` — chunk id → embedding vector.

Content-hash keyed per chunk. **Every search auto-refreshes the index
first** — the incremental content-hash pass runs before the query embeds,
re-embedding only changed or new files (typically zero or a few), so
results can never be stale and there is no separate reindex step, git
hook, or scheduled job required in normal use. Pass `--no-refresh` to skip
that pass for speed when you already know the index is current (e.g.
running several searches back-to-back with no edits in between).
`--reindex` forces a full rebuild from scratch (useful after bulk file
moves, or if the cache looks corrupted). Deleting `.docs-embeddings/`
entirely is always safe — it's a cache, not a record; the next search
rebuilds it.

## Troubleshooting

- **Model download fails or is slow.** Corporate proxy or flaky network —
  retry, or set `HF_HUB_OFFLINE=0` explicitly. If downloading isn't
  practical on this machine, semantic search just isn't available here;
  `scripts/browse.py` and grep still work for everything, and searching
  notes before starting new work (see `references/routing.md`) still
  applies, just via grep instead.
- **Not on Apple Silicon.** MLX doesn't run. Two options: skip semantic
  search entirely (grep + browse cover the routine cases), or point a
  small custom script at the Jina Embeddings API instead of a local model
  — that's a different script than this one; this template is
  local-only by design (no API key, no network dependency after the
  first download, works offline).
- **`uv run` can't resolve `mlx`.** Confirms you're not on Apple Silicon,
  or `uv`'s Python target isn't `cpython-*-macos-aarch64` — check
  `uv python list`.
- **Results look wrong.** A normal search already re-embeds anything
  changed before searching, so staleness isn't the usual cause — try
  `--reindex` (full rebuild) first, and if that doesn't fix it, delete
  `.docs-embeddings/` and search again.
