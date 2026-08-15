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

## Chunking — what the script does and what that means for writing

Files at or under roughly 1500 tokens embed as a single whole-file chunk.
Longer files split at markdown headings (each section capped near 512
tokens, oversized sections split again at paragraphs), with no overlap;
each chunk embeds with a contextual prefix carrying the file path,
heading path, and the file's first-line summary. Heading paths nest by
actual heading level, so documents that start at `##` (the normal case
here — line 1 is a plain sentence, not a heading) chunk correctly.

Empirically validated (adversarial test corpus, 2026-08-16, this exact
model and script): conceptual queries land the right section of a long
document even when the fact is a single sentence buried mid-file
(~0.62–0.65); two near-identical result tables in sibling sections are
discriminated correctly by their headings (correct section top in both
directions at ~0.67); vocabulary drift resolves well ("double exposure
artifacts from motion" → the ghosting note at 0.70); checkbox task lists
score well below their prose equivalents (~0.45 vs ~0.65) but never
outrank them — skipping openspec `tasks.md` is noise reduction, not a
correctness requirement. Queries for a bare numeric value ("which arm
had p95 7.81") still resolve to the right *file* but at ~0.35 — exactly
the weak-match footer threshold, which is why that footer tells you to
switch to grep.

Writing guidance this implies (only two rules, both cheap):

- **In any document long enough to split (~1500+ tokens), use real,
  descriptive headings.** Retrieval of a buried fact rides on its
  section's heading and text; a wall of prose under one vague heading
  chunks by paragraph with no useful heading context.
- **When two sections hold near-identical content (per-scenario result
  tables, per-arm configs), let the headings name what differs**
  ("Dense scenario results" / "Sparse scenario results"). The model
  separates them cleanly when the distinguishing term is in the heading
  or nearby prose.

No overlap, reranker, BM25 hybrid, or bigger model is warranted — the
tested failure modes are covered by the routing rules (numbers → grep)
and the display columns (date, authority class).

## Retrieval — how to query well

The routing rules (when to search vs grep) live in
`references/routing.md` and the repo's `docs/CLAUDE.md`. On top of
those, phrasing matters:

- **One concept per query, phrased as a short natural sentence.** "why
  was GPU-side fragment sorting rejected" beats "GPU sorting atomics".
  Several concepts ORed into one query dilute all of them — run two
  queries instead.
- **Use the domain's own vocabulary when you know it, and plain
  description when you don't** — vocabulary drift is exactly what the
  embeddings absorb ("double exposure artifacts from motion" finds the
  ghosting note at 0.70 with zero shared keywords).
- **Iterate once, then switch tools.** A weak top score (<0.35, the
  tool warns) after one rephrase means the answer isn't in the docs
  semantically — grep, browse, or say so.
- **Keep `-k` small and read the files.** Result rows are pointers;
  the top 1–3 files opened and read is the retrieval, not the row's
  summary line. `--json` exists for programmatic consumers, not for
  quoting.
- **Trust the columns.** Date and authority-class tags exist so a
  dated note from last spring doesn't beat the current spec; apply the
  doctrine before acting on a hit.

## Index lifecycle — creating and maintaining embeddings

Nothing to schedule. The first search builds the index (model download
~424MB once per machine, then ~1s warm); every later search runs the
incremental content-hash refresh first, so only new or changed files
re-embed. `--reindex` is for bulk moves or a suspect cache;
deleting `.docs-embeddings/` is always safe. The status line surfaces a
stale or missing index, and concurrent sessions are safe (flock +
atomic writes). The only human-side input to index quality is the
writing guidance above — heading structure is the chunk structure.

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
