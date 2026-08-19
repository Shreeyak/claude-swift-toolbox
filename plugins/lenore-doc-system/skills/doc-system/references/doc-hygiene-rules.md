# Doc hygiene rules — the single rulebook

The one canonical copy of the judgment hygiene rules. Three consumers:
the commit-time judge (`doc-lint-judge` — its inline prompt carries only
the pattern-level tells, derived from here), the landing reviewer
(`landing-doc-reviewer` — reads this file before judging), and the
health auditor (`doc-health-auditor` — same). Edit rules HERE; the
regression suite in `tests/doc-lint/` mirrors every example below.

False positives are worse than misses, in every rule. When unsure, pass.

## Where each rule applies

| Rule | journal/ + notes/ | living docs (spine, READMEs, proposals) | code docstrings/comments |
|---|---|---|---|
| No invented entry IDs | yes | yes | yes |
| Session-opaque references | yes — highest value: these files are immutable | yes | yes |
| History narration / present tense | NO — narration is their job | yes | yes |
| Reviewer-directed comments | yes | yes | yes |

## 1. No invented entry IDs

Never invent serial, ordinal, categorical, date-based, or otherwise
systematic identifiers for documentation entries — no `C1`, `P3`,
`ADR-###`, `D-12`, and no prefix/suffix scheme whose job is ordering,
uniqueness, classification, or lookup rather than describing the entry.
Entries get short descriptive, content-derived slug names, cited by name
in plain words.

Carve-out — identifiers that belong to the documented domain are
untouched: versions, standards (RFC 9110, SHA-256), metrics (P95, P99),
HTTP codes, issue numbers, commit hashes, and the sanctioned experiment
run ids (`run012`). Writing ABOUT them is fine; repurposing one to
organize docs is not.

- VIOLATION: `## C4 — seam drift` as a caveat heading; "per P3" as a
  citation; a premises list numbered `**P1 —** … **P2 —** …`.
- VIOLATION: caveat slugs `a-seam-drift`, `b-tile-cache` (alphabetical
  ordering smuggled into names); `phase-one-masking`, `priority-high-*`
  prefixes used across entries as a classification scheme.
- OK: `## P95 latency regression on batch resize` — P95 is a metric of
  the documented domain, not an entry address.
- OK: "run012 measured 2.1px mean error" — run ids are the sanctioned
  scheme for experiment run records; likewise CVE/RFC/issue numbers and
  commit hashes cited as facts.
- BOUNDARY-OK: `## v2-pipeline rollout risks` where `v2-pipeline` is the
  actual name of a shipped pipeline (a directory or module by that name
  exists) — the name belongs to the domain. Flag only if `v2` names
  nothing in the repo.

## 2. Session-opaque references

Every name a doc uses must be resolvable by a fresh reader with only the
repo. The operational test: the name is **defined near first use** or
resolves to a canonical artifact — a path, symbol, experiment dir,
branch, or config key that exists. A grep hit alone is not resolution
(an opaque token repeated ten times is still opaque); the hit must be a
*defining* occurrence. This matters most in journal/notes — they are
immutable, so an opaque name frozen at commit is opaque forever.

- VIOLATION: "went with the alpha-cut approach" — no file, dir, symbol,
  or definition named alpha-cut anywhere.
- VIOLATION: "v2 fixes the drift" — v2 of *what*? No artifact named v2;
  version of the matcher, the pipeline, the dataset?
- OK: "the masked-ncc experiment showed 2.1px error" —
  `experiments/2026-08-18-masked-ncc/` exists.
- OK: "the b2 branch (feature/blend-2pass) merges tomorrow" — codename
  defined at first use.
- BOUNDARY-OK: a note that opens "'tile-first' below means computing
  placement per tile before global refine" and then uses tile-first
  throughout — defined near first use, do not flag later uses.

## 3. History narration — present tense, contract not chronicle

Living docs and docstrings state the **current contract**: what it does,
why it is shaped this way, and context the code cannot carry. Present
tense. The past appears only as a guard rail — when a future agent would
plausibly reintroduce the mistake — and is phrased as a standing fact,
not a story. Superseded lines are deleted, not marked; no
"(previously…)", no OBSOLETE/superseded annotations, no
changelog-in-docstring.

Does NOT apply to journal entries and dated notes — narrating the past
is their purpose. Deprecation notices and migration guidance may
reference the old behavior — that reference IS their current contract.

- VIOLATION: "We used to warp directly, but the user reported crashes,
  and after our research surfaced the stride problem we decided to clamp
  first." — chronicle. The contract version: "cv2.warpAffine segfaults
  on zero-height ROIs, so we clamp first."
- VIOLATION: "~~tau defaults to 0.4~~ (superseded — now 0.2 as of the
  August refactor)" — delete the dead line; write "tau defaults to 0.2."
- OK: "Retries are capped at 3: the upstream API bans clients that
  hammer it, and an uncapped retry loop triggered a 24h ban once." —
  past event kept as a guard rail, phrased as the standing reason.
- BOUNDARY-OK: "introduced to prevent the zero-height crash" — a
  past-tense verb, but it states the current contract's purpose, not a
  chronicle. Do not flag on tense alone.
- BOUNDARY-OK: "Deprecated: use `place_tiles()` — this shim keeps the
  v1 call sites compiling until the migration lands." — deprecation
  notices legitimately name the old world.

## 4. Reviewer-directed comments

Docs and comments address the next reader, never the person who
requested the change. Conversation residue — "now correctly handles…",
"fixed to…", "as requested", "per your feedback" — is deleted; the tell
is the *editing narrative* (now/fixed/as-requested), not any particular
word.

- VIOLATION: "Now correctly handles negative strides (fixed per
  review)."
- OK: "Handles negative strides: OpenCV flips the sign on reversed-axis
  views, so we normalize before the copy." — the same fact as contract.
- BOUNDARY-OK: "Unlike `fast_resize`, this path handles negative
  strides." — "correctly/handles" contrasting a documented sibling is
  contract, not edit commentary.
