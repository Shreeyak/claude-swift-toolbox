# Experiment README + notebook entry templates

Spec for the two document shapes in the final experiment system. Governing principle:
**frontmatter is the envelope** (one-line facts that machines scan — the conclusion gate,
status line, browse listings, the judge), **headings are the letter** (prose a reader needs
to comprehend the experiment). Every one-liner that a hook or listing reads lives in
frontmatter; everything verbose lives under a heading. The README is rewritten freely as
understanding changes; it carries zero run-by-run narrative — that is notebook/'s job.

---

## 1. README.md template

```markdown
---
status: exploring            # REQUIRED  exploring | concluded | shelved
question: <one line — what this experiment decides>            # REQUIRED
verdict: <one sentence answer>       # REQUIRED at conclusion (gate-checked); empty until known
concluded: YYYY-MM-DD                # REQUIRED at conclusion (gate-checked)
success: <one line — what result would settle it>              # optional, written at creation
uses: [2026-06-01-gpu-pc]            # optional — experiments whose code this one reuses
extends: 2026-05-12-plain-ncc        # optional — prior experiment this question builds on
---

# <Experiment name in plain words>

## Question
REQUIRED. The full framing the frontmatter one-liner compresses: what is being decided,
why it matters to the project, what triggered it, definitions a stranger needs. If
`extends:` is set, one sentence on what the prior experiment established.

## Approach
RECOMMENDED. How the experiment works mechanically: the entry-point scripts and what a
run does (`sweep.py` grids tau, writes per-clip NCC to out/), key parameters, anything
an agent needs to *operate* the experiment cold. This is comprehension-of-the-machine;
findings never go here.

## Data
REQUIRED once the experiment touches data. What the inputs are and where they come from:
shared datasets used (`data/datasets/...`), what `keep/` holds and why it is
irreplaceable, and the exact command that rebuilds `regen/`. This section IS the
regen manifest — no separate file.

## Findings
REQUIRED once runs exist. The current understanding, as prose: what works, what the
numbers say, each claim citing its evidence by run id ("masking wins below tau 0.35
(run002, run005)"). Rewritten freely as runs change the picture — this is the section
the verdict-staleness counter and the judge's contradiction check are really about.

## What didn't work
RECOMMENDED. The anti-survivorship record: approaches tried and abandoned, with the run
id that killed each. Saves every future session from re-walking dead ends.

## Recommendations
CONCLUSION-TIME. What production should do about it: what to adopt, parameter values,
integration notes. If code was promoted, name the destination and the PROMOTIONS.md
entry. (For shelved experiments: what would justify reopening.)

## Caveats
OPTIONAL. Conditions under which the verdict holds — dataset scope ("12 indoor clips
only"), assumptions, known threats to validity. Where verdict-rot becomes visible
instead of silent.

## Open questions
OPTIONAL. What this experiment surfaced but did not answer — the seed list for
`extends:` follow-ons and Someday entries.

---
History: notebook/ — catch up with `cat notebook/*.md`
```

Section order is fixed (comprehension order: what/how/inputs → results → judgment);
optional sections are simply omitted, never left as empty headings. The closing History
line is a fixed one-liner, not a heading.

## 2. Filled example (concluded experiment)

```markdown
---
status: concluded
question: does masked NCC beat plain NCC on low-texture stitch alignment?
verdict: masked NCC wins decisively on low-texture clips (+0.19 NCC) at tau<=0.35 and is never worse; adopt with tau=0.3.
concluded: 2026-09-02
success: masked variant improves mean NCC by >=0.05 on the hard-clip set without regressing textured clips
uses: [2026-06-01-gpu-pc]
extends: 2026-05-12-plain-ncc
---

# Masked NCC vs plain NCC

## Question
Plain NCC (2026-05-12-plain-ncc) established our alignment baseline but collapses on
low-texture regions — adipose tissue, glass background — where the correlation window is
dominated by noise. This experiment decides whether masking the window to
gradient-bearing pixels beats plain NCC enough to justify the extra mask pass, and at
what threshold tau.

## Approach
`match.py` runs one alignment pass over a clip list with `--masked/--plain` and `--tau`;
`sweep.py` grids tau and fans out to `match.py`, writing per-clip NCC and timing CSVs to
the run's out/ dir. Kernels are reused from gpu-pc (`-I ../2026-06-01-gpu-pc`). A run on
the 12-clip hard set takes ~4 min on the M3 Max.

## Data
- Shared: `data/datasets/cmu-stitch-v2/` — the standard 40-clip benchmark.
- `keep/`: 12 hand-picked hard clips (low-texture failures from production logs,
  irreplaceable — the selection judgment cannot be regenerated).
- `regen/`: gaussian pyramids per clip; rebuild with `python gen_pyramids.py --all`.

## Findings
Masked NCC improves mean NCC from 0.64 to 0.83 on the hard set at tau=0.3 (run002), and
is within noise of plain NCC on textured clips (run003) — no regression case found.
The win is threshold-sensitive: tau>=0.4 over-masks and collapses to 0.61 (run002);
tau=0.3 is the plateau center. Outdoor clips confirm the pattern at slightly lower
magnitude, +0.11 (run005). Cost: mask pass adds 8% wall time (run004), flat across tau.

## What didn't work
- Entropy-based masking instead of gradient: no better than gradient and 3x the cost
  (run001).
- Adaptive per-window tau: unstable, oscillates on boundary windows (run006); fixed
  global tau is both simpler and better.

## Recommendations
Adopt masked NCC with fixed tau=0.3 in the production matcher. Promoted
`masked_ncc.py` kernel logic into `Packages/StitchCore/Matching/` — see PROMOTIONS.md
2026-09-02. Keep plain NCC as the fallback path for the mask-degenerate case (<5% of
windows carrying gradient), which the promoted code handles.

## Caveats
Measured on 1080p indoor pathology clips plus one 8-clip outdoor set; tau=0.3 was not
re-tuned for other resolutions. Timing numbers are M3 Max Metal; the 8% overhead may
differ on A-series.

## Open questions
- Does the mask transfer to the phase-correlation prefilter, or is the win NCC-specific?
- tau sensitivity at 4K — the window statistics change with resolution.

---
History: notebook/ — catch up with `cat notebook/*.md`
```

## 3. Notebook entry template

```markdown
# runNNN[-slug] — YYYY-MM-DD
<Line-1 outcome summary: one sentence stating what this run established.>

command: <exact invocation>
commit:  <hash, or "uncommitted — see date">
inputs:  <dataset / keep / regen identity, precise enough to re-run>
outputs: data/out/runNNN[-slug]/

## What happened
REQUIRED (prose). The narrative of the run: what was actually done and observed —
including surprises, failures, partial results, anything a bare metric hides. For a
sweep: the shape of the result across points, not just the best point.

## Interpretation
REQUIRED (prose). What the result means for the question: what it confirms or kills,
how confident, what it says the next run should be. This is the analysis the README's
Findings section will later compress and cite.
```

Rules and rationale:
- **Line 1 after the header is a one-sentence outcome summary** — same envelope rule as
  notes and journal entries. This is what makes `cat notebook/*.md` skimmable and gives
  grep/listings a target. (First fork's highest-value item; adopted.)
- The four **anchor lines** (command/commit/inputs/outputs) stay label-style, not YAML
  frontmatter — they are for humans re-running the thing; the judge already checks their
  presence as evidence anchors. `outputs:` is nominally redundant (name-join) but makes
  the record self-contained when read alone.
- **Both prose sections required**, but a short run may legitimately be 2–3 sentences
  each — the requirement is "explanations and analysis exist", not length. A code-free
  analysis entry (e.g. `run009-compare-tau-sweeps.md`) uses the same shape with
  `command:` naming what was analyzed.
- **Optional fenced metrics block** (` ```yaml metrics `) at the end for projects that
  plot across runs — convention only, never validated. (Adopted from first fork.)
- Entries are immutable on commit; a wrong entry is corrected by a later entry that
  says so, never by editing.

## 4. Filled example entry

```markdown
# run002-tau-sweep — 2026-08-20
Masking only helps below tau 0.35; best NCC 0.83 at tau=0.3, collapse to 0.61 at tau>=0.4.

command: python sweep.py --tau 0.1:0.5:0.1 --clips data/keep --masked
commit:  abc1234
inputs:  keep/ hard clips (12), regen/pyramids-v2
outputs: data/out/run002-tau-sweep/

## What happened
Swept tau over 0.1–0.5 in 0.1 steps on the hard-clip set. NCC rises monotonically to a
plateau at 0.3 (0.83), then falls off a cliff past 0.35 — at 0.4 the mask discards so
many windows that three clips lose alignment entirely, dragging the mean to 0.61. The
plateau is flat between 0.25 and 0.35, so the operating point is not knife-edge. One
surprise: clip hard-07 (glass background) improves the most (+0.31), suggesting the win
concentrates exactly where plain NCC was worst.

## Interpretation
Confirms the masking hypothesis with a wide safe plateau; tau=0.3 is the pick. The
cliff at 0.4 kills any "more masking is better" intuition — over-masking is a real
failure mode the production code must clamp against. Next: verify no regression on
textured clips (run003) before touching timing.

```yaml metrics
best_tau: 0.3
mean_ncc_at_best: 0.83
mean_ncc_at_0.4: 0.61
```
```

## 5. Rejected, and why

- **Run-index table in the README** — hand-kept index agents forget; `ls notebook/` +
  browse.py derive it. (Settled earlier; stays rejected.)
- **`data:` frontmatter key** (first fork) — duplicates the `## Data` heading, and
  nothing machine-scans it now that the manifest lives in the README.
- **Separate `data/manifest.md`** (first fork) — one more file per experiment; the
  README's Data section is the manifest.
- **`lifted:` frontmatter key** — promotion is prose + a PROMOTIONS.md line; a scalar
  duplicates a ledger nothing scans.
- **HHMM anywhere** (first fork's collision fix) — user-rejected; the runNNN counter and
  mkdir-reservation solve the collision instead.
- **Changelog / "story so far" section in README** — narrative belongs to notebook/;
  git history is the README's changelog.
- **Per-run JSON sidecars** — doubles file count, splits evidence from interpretation;
  the optional metrics block covers the need.
- **Per-project-type template variants** — publication run / bench trial / library
  comparison all fit command + inputs + result + interpretation; only the letters differ.
- **Required `success:`** — preregistration discipline is worth an optional line, not a
  gate; forcing it invites boilerplate.

## 6. Judge/gate touchpoints (so the templates stay enforceable)

- Conclusion gate keeps reading frontmatter `verdict:` + `concluded:` — unchanged.
- The judge's contradiction check targets frontmatter `verdict:` and the `## Findings`
  section (was "What worked" in older prompt text — update wording when implementing).
- Shape check gains: notebook entry line 1 (after the `# ` header) must be a sentence,
  not a heading or an anchor line.
- `question:` frontmatter feeds browse/status listings so unconcluded experiments are
  scannable before a verdict exists.
