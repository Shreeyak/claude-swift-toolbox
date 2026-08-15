#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["mlx", "tokenizers", "huggingface_hub", "numpy"]
# ///
# usage: uv run scripts/docs-search.py "query text" [-k N] [--json] [--reindex] [--no-refresh] [--status]
# what it does: local semantic search over docs/**/*.md, docs/**/*.html, and
# experiments/*/README.md using jina-embeddings-v5-text-nano on MLX (Apple
# Silicon). Every search auto-refreshes the index first (incremental,
# content-hash keyed — only changed/new files re-embed, usually zero or a
# few) so results can never be stale; pass --no-refresh to skip that pass
# for speed if you know the index is already current. Optional — see
# references/semantic-search-setup.md in the doc-system skill for when to
# bother installing this at all.
#
# --- what was verified before writing this ---
# Model:   jinaai/jina-embeddings-v5-text-nano-retrieval-mlx
#          https://huggingface.co/jinaai/jina-embeddings-v5-text-nano-retrieval-mlx
#          EuroBERT-210M backbone, retrieval LoRA, last-token pooling,
#          "Query: " / "Document: " prefixes — confirmed via the repo's own
#          model.py and README (fetched 2026-08-16).
# Weights: this repo ships ONLY float16 safetensors (model.safetensors,
#          ~424MB / 211M params). Checked the HF API file listing directly —
#          no model-8bit.safetensors, and no mlx-community mirror exists for
#          this specific model (searched both orgs). There is no
#          pre-quantized MLX checkpoint to point at, so this script runs the
#          float16 weights directly (no in-process quantization — user
#          decision, keeps behavior identical to the published checkpoint).
#          fp16 weights measure ~424MB on disk; measured resident memory
#          during inference is in semantic-search-setup.md.
# Package: the model card's own usage sample is plain `mlx` + the repo's own
#          model.py (a small, dependency-free nn.Module — NOT a pip
#          package). Checked Blaizzy/mlx-embeddings (the closest published
#          package): its supported architecture list does not include
#          EuroBERT/Jina-v5, so it does not run this model. We therefore
#          download model.py from the model repo itself (dynamic import,
#          not installed) exactly as the model card documents.
# License: cc-by-nc-4.0 (non-commercial) — fine for an internal dev tool;
#          flag before using in anything shipped externally.

from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path

MODEL_REPO = "jinaai/jina-embeddings-v5-text-nano-retrieval-mlx"
MODEL_FILES = ["config.json", "model.py", "model.safetensors", "tokenizer.json"]

ROOT = Path(
    __import__("subprocess")
    .run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    .stdout.strip()
    or "."
)
CACHE_DIR = ROOT / ".docs-embeddings"
VECTORS_FILE = CACHE_DIR / "vectors.npz"
META_FILE = CACHE_DIR / "meta.json"

CHARS_PER_TOKEN = 4
WHOLE_FILE_TOKEN_LIMIT = 1500
CHUNK_TOKEN_CAP = 512

SKIP_DIRS = {"docs/desk", "tmp"}


def est_tokens(text: str) -> int:
    return max(1, len(text) // CHARS_PER_TOKEN)


def strip_html(text: str) -> str:
    return re.sub(r"<[^>]+>", " ", text)


def first_line(text: str) -> str:
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        # Skip YAML front matter (e.g. experiment README status/verdict).
        for i, line in enumerate(lines[1:], start=1):
            if line.strip() == "---":
                lines = lines[i + 1 :]
                break
    for line in lines:
        line = line.strip().lstrip("#").strip()
        if line and not line.startswith("<!--"):
            return line
    return ""


def split_headings(text: str) -> list[tuple[str, str]]:
    """Return [(heading_path, section_text), ...] split on markdown headings."""
    lines = text.splitlines()
    sections: list[tuple[str, str]] = []
    stack: list[str] = []
    buf: list[str] = []

    def flush():
        if buf:
            sections.append((" › ".join(stack), "\n".join(buf).strip()))
            buf.clear()

    for line in lines:
        m = re.match(r"^(#{1,6})\s+(.*)", line)
        if m:
            flush()
            level = len(m.group(1))
            stack[level - 1 :] = [m.group(2).strip()]
        else:
            buf.append(line)
    flush()
    return sections or [("", text)]


def split_paragraphs_capped(text: str, cap: int) -> list[str]:
    paras = re.split(r"\n\s*\n", text)
    chunks: list[str] = []
    cur: list[str] = []
    cur_tokens = 0
    for p in paras:
        t = est_tokens(p)
        if cur and cur_tokens + t > cap:
            chunks.append("\n\n".join(cur))
            cur, cur_tokens = [], 0
        cur.append(p)
        cur_tokens += t
    if cur:
        chunks.append("\n\n".join(cur))
    return [c for c in chunks if c.strip()]


def chunk_file(path: Path) -> list[dict]:
    """Return [{heading, text}, ...] chunks for one file, no overlap."""
    raw = path.read_text(errors="replace")
    text = strip_html(raw) if path.suffix == ".html" else raw
    if est_tokens(text) <= WHOLE_FILE_TOKEN_LIMIT:
        return [{"heading": "", "text": text.strip()}]

    chunks = []
    for heading, section in split_headings(text):
        if est_tokens(section) <= CHUNK_TOKEN_CAP:
            if section.strip():
                chunks.append({"heading": heading, "text": section.strip()})
        else:
            for part in split_paragraphs_capped(section, CHUNK_TOKEN_CAP):
                chunks.append({"heading": heading, "text": part})
    return chunks


def iter_doc_files():
    for pattern in ("docs/**/*.md", "docs/**/*.html", "experiments/*/README.md"):
        for p in ROOT.glob(pattern):
            rel = p.relative_to(ROOT).as_posix()
            if any(rel.startswith(s) for s in SKIP_DIRS):
                continue
            if p.is_file():
                yield p


def load_model():
    from huggingface_hub import snapshot_download

    local_dir = Path(
        snapshot_download(repo_id=MODEL_REPO, allow_patterns=MODEL_FILES)
    )

    spec = importlib.util.spec_from_file_location("_jina_mlx_model", local_dir / "model.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    import mlx.core as mx
    from tokenizers import Tokenizer

    config = json.loads((local_dir / "config.json").read_text())
    model = mod.JinaEmbeddingModel(config)
    weights = mx.load(str(local_dir / "model.safetensors"))
    model.load_weights(list(weights.items()))
    mx.eval(model.parameters())

    tokenizer = Tokenizer.from_file(str(local_dir / "tokenizer.json"))
    return model, tokenizer


def embed(model, tokenizer, texts: list[str]) -> "list[list[float]]":
    # task_type="raw" is unmatched in the model's own prefix map, so it adds
    # no prefix — we've already applied our own "Query: "/"Document: " one.
    out = model.encode(texts, tokenizer, task_type="raw")
    return [[float(x) for x in row] for row in out.tolist()]


def content_hash(*parts: str) -> str:
    h = hashlib.sha256()
    for p in parts:
        h.update(p.encode())
        h.update(b"\0")
    return h.hexdigest()[:16]


def build_index(force: bool = False):
    import numpy as np

    meta = {} if force or not META_FILE.exists() else json.loads(META_FILE.read_text())
    vectors = {} if force or not VECTORS_FILE.exists() else dict(np.load(VECTORS_FILE))

    to_embed: list[tuple[str, str]] = []  # (chunk_id, prefixed_text)
    new_meta = {}
    for path in iter_doc_files():
        rel = path.relative_to(ROOT).as_posix()
        summary = first_line(path.read_text(errors="replace"))
        for chunk in chunk_file(path):
            cid = content_hash(rel, chunk["heading"], chunk["text"])
            new_meta[cid] = {
                "path": rel,
                "heading": chunk["heading"],
                "summary": summary,
            }
            if cid not in vectors:
                header = f"Document: {summary} › {chunk['heading']}".rstrip(" ›")
                to_embed.append((cid, f"{header}\n{chunk['text']}"))

    if to_embed:
        model, tokenizer = load_model()
        batch_size = 16
        for i in range(0, len(to_embed), batch_size):
            batch = to_embed[i : i + batch_size]
            embs = embed(model, tokenizer, [t for _, t in batch])
            for (cid, _), vec in zip(batch, embs):
                vectors[cid] = np.array(vec, dtype=np.float32)

    # Drop stale entries (files/chunks that no longer exist).
    stale = set(vectors) - set(new_meta)
    for cid in stale:
        vectors.pop(cid, None)

    CACHE_DIR.mkdir(exist_ok=True)
    META_FILE.write_text(json.dumps(new_meta, indent=2))
    np.savez(VECTORS_FILE, **vectors)
    return new_meta, vectors


def load_cached_index():
    """Load the on-disk index as-is, no filesystem scan or re-embedding."""
    import numpy as np

    meta = json.loads(META_FILE.read_text()) if META_FILE.exists() else {}
    vectors = dict(np.load(VECTORS_FILE)) if VECTORS_FILE.exists() else {}
    return meta, vectors


def search(query: str, k: int, refresh: bool = True) -> list[dict]:
    import numpy as np

    # Auto-refresh by default: every search does the incremental
    # content-hash pass first (only changed/new files re-embed, typically
    # zero or a few), so results can never be stale and no manual reindex
    # or git hook is required in normal use. --no-refresh skips this for
    # speed when the caller knows the index is current.
    meta, vectors = build_index() if refresh else load_cached_index()
    if not vectors:
        return []

    model, tokenizer = load_model()
    [qvec] = embed(model, tokenizer, [f"Query: {query}"])
    qvec = np.array(qvec, dtype=np.float32)

    scored = []
    for cid, vec in vectors.items():
        if cid not in meta:
            continue
        sim = float(np.dot(qvec, vec) / (np.linalg.norm(qvec) * np.linalg.norm(vec) + 1e-9))
        scored.append((sim, cid))
    scored.sort(reverse=True)

    # Dedupe by file — best-scoring chunk wins.
    seen_paths = set()
    results = []
    for sim, cid in scored:
        m = meta[cid]
        if m["path"] in seen_paths:
            continue
        seen_paths.add(m["path"])
        results.append({"score": round(sim, 4), **m})
        if len(results) >= k:
            break
    return results


def print_status():
    from huggingface_hub import scan_cache_dir

    print(f"cache dir: {CACHE_DIR}")
    if META_FILE.exists():
        meta = json.loads(META_FILE.read_text())
        files = {m["path"] for m in meta.values()}
        size = VECTORS_FILE.stat().st_size if VECTORS_FILE.exists() else 0
        print(f"indexed: {len(meta)} chunks across {len(files)} files ({size // 1024} KB)")
    else:
        print("indexed: no index yet (run a search to build one)")

    found = False
    try:
        info = scan_cache_dir()
        for repo in info.repos:
            if repo.repo_id == MODEL_REPO:
                found = True
                print(f"model: {MODEL_REPO} present in HF cache ({repo.size_on_disk / 1e6:.0f} MB)")
    except Exception:
        pass
    if not found:
        print(f"model: {MODEL_REPO} not downloaded yet (~250-450MB on first search)")


def main():
    args = sys.argv[1:]
    if "--status" in args:
        print_status()
        return

    as_json = "--json" in args
    reindex = "--reindex" in args
    no_refresh = "--no-refresh" in args
    k = 8
    if "-k" in args:
        k = int(args[args.index("-k") + 1])
    positional = [
        a
        for i, a in enumerate(args)
        if not a.startswith("-") and (i == 0 or args[i - 1] != "-k")
    ]

    if reindex:
        build_index(force=True)
        if not positional:
            print("reindex complete.")
            return

    if not positional:
        print(
            "usage: docs-search.py \"query text\" [-k N] [--json] [--reindex] "
            "[--no-refresh] [--status]"
        )
        sys.exit(1)

    query = " ".join(positional)
    results = search(query, k, refresh=not (no_refresh or reindex))

    if as_json:
        print(json.dumps(results, indent=2))
        return
    if not results:
        print("no results (index empty or no matches)")
        return
    for r in results:
        heading = f" [{r['heading']}]" if r["heading"] else ""
        print(f"{r['score']:.3f}  {r['path']}{heading}  — {r['summary']}")


if __name__ == "__main__":
    main()
