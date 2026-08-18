#!/usr/bin/env python3
"""lenore-docs — create Lenore doc-system entries with correct names, shapes, and links.

Automates the mechanical part of filing (dated filenames, shape caps, task↔note
pointers) so it can't be gotten wrong; all judgment (what class, what to say)
stays with the caller. Plain Write remains a valid fallback — this tool is the
convenient path, not a gate. The git hooks are the enforcement layer.

Usage (body is read from stdin — use a heredoc — or --body-file):

  lenore-docs note "One-sentence summary" [--topic slug] [--supersedes notes/OLD.md] <<'EOF'
  Full prose body...
  EOF

  lenore-docs bug "One-sentence summary of the bug" [--topic slug] <<'EOF'
  Repro, expected vs actual, suspicion...
  EOF

  lenore-docs journal "One-sentence event summary" [--topic slug] [<<'EOF' extra lines EOF]

  lenore-docs task "Self-contained one-line title" [--someday | --branch] [--note] [<<'EOF' context EOF]
      Inline context must be <=5 lines. Longer context: pass --note and the
      body becomes a dated note in docs/notes/, with a pointer appended to
      the task line automatically.

  lenore-docs experiment "short name" [--question "one line"]
      Creates experiments/YYYY-MM-DD-<slug>/ with a README skeleton,
      notebook/, the data symlink, and the store trio
      data/experiments/<same>/{regen,keep,out}.

  lenore-docs run <experiment> [slug]
      Reserves the next run id (max across notebook/ and the store's out/,
      +1) by creating data/experiments/<exp>/out/runNNN[-slug]/, and prints
      the notebook entry path to write when the run means something.
      <experiment> may be the dated dir name or a unique substring of it.

Run from anywhere inside the repo; paths resolve from the git root.
Install globally (optional): ln -s "$REPO/scripts/lenore-docs.py" ~/.local/bin/lenore-docs
(the symlink works for every repo — the script resolves the repo from your cwd).
"""

import argparse
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

SUMMARY_MAX = 140
TASK_CONTEXT_MAX_LINES = 5
JOURNAL_MAX_LINES = 10
JOURNAL_MAX_WORDS = 150


def die(*lines):
    for line in lines:
        print(line, file=sys.stderr)
    sys.exit(1)


def repo_root():
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except subprocess.CalledProcessError:
        die("lenore-docs: not inside a git repository.")
    return Path(out)


def read_body(args):
    if args.body_file:
        p = Path(args.body_file)
        if not p.is_file():
            die(f"lenore-docs: --body-file {p} does not exist.")
        return p.read_text().strip()
    if sys.stdin.isatty():
        return ""
    # In agent shells stdin is an open pipe even when nothing is piped; a bare
    # read() would hang forever. Heredoc content is already in the pipe buffer
    # at exec time, so a short poll cleanly separates "body provided" from
    # "no body". Large bodies belong in --body-file.
    import select
    ready, _, _ = select.select([sys.stdin], [], [], 0.3)
    return sys.stdin.read().strip() if ready else ""


def slugify(text, explicit):
    if explicit:
        s = explicit
    else:
        s = " ".join(text.split()[:6])
    s = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
    if not s:
        die("lenore-docs: could not derive a filename slug; pass --topic.")
    return s


def check_summary(summary):
    if "\n" in summary:
        die("lenore-docs: the summary must be a single line (it becomes line 1 of the file).")
    if len(summary) > SUMMARY_MAX:
        die(
            f"lenore-docs: summary is {len(summary)} chars (max {SUMMARY_MAX}).",
            "Line 1 is what listings and search results show — tighten it;",
            "detail belongs in the body.",
        )
    if not summary.strip():
        die("lenore-docs: summary is empty.")


def fresh_path(directory, name):
    """Refuse to touch existing files — committed docs are immutable."""
    path = directory / name
    if path.exists():
        die(
            f"lenore-docs: {path} already exists and committed docs are immutable.",
            "Pick a different --topic, or if you're revisiting the topic this is a",
            "new entry — today's date plus a more specific slug.",
        )
    return path


def write_doc(path, summary, body):
    path.parent.mkdir(parents=True, exist_ok=True)
    text = summary.strip() + ("\n\n" + body + "\n" if body else "\n")
    path.write_text(text)
    return path


def resolve_supersedes(root, ref):
    rel = ref.strip().lstrip("./")
    if not rel.startswith("docs/"):
        rel = "docs/" + rel  # accept "notes/x.md" shorthand
    if not (root / rel).is_file():
        die(
            f"lenore-docs: --supersedes target {rel} not found.",
            "Name the existing note as docs/notes/YYYY-MM-DD-topic.md (or notes/...).",
        )
    return rel


def cmd_note(root, args, body):
    check_summary(args.summary)
    if not body and not args.supersedes:
        die(
            "lenore-docs: a note needs a body — pipe it via a heredoc:",
            '  lenore-docs note "summary" <<\'EOF\'',
            "  ...details...",
            "  EOF",
        )
    if args.supersedes:
        rel = resolve_supersedes(root, args.supersedes)
        body = f"Revises {rel}.\n\n{body}" if body else f"Revises {rel}."
    name = f"{datetime.now():%Y-%m-%d}-{slugify(args.summary, args.topic)}.md"
    path = write_doc(fresh_path(root / "docs/notes", name), args.summary, body)
    print(path.relative_to(root))


def cmd_bug(root, args, body):
    check_summary(args.summary)
    if not body:
        die(
            "lenore-docs: a bug file needs a body (repro, expected vs actual, suspicion) —",
            "pipe it via a heredoc. A summary alone won't be actionable later.",
        )
    name = f"{datetime.now():%Y-%m-%d}-{slugify(args.summary, args.topic)}.md"
    path = write_doc(fresh_path(root / "docs/bugs", name), args.summary, body)
    print(path.relative_to(root))
    print("(delete this file in the commit that fixes the bug — the commit-msg hook checks fix claims)",
          file=sys.stderr)


def cmd_journal(root, args, body):
    check_summary(args.summary)
    full = args.summary + ("\n" + body if body else "")
    lines = [l for l in full.splitlines() if l.strip()]
    words = len(full.split())
    problems = []
    if len(lines) > JOURNAL_MAX_LINES:
        problems.append(f"{len(lines)} lines (max {JOURNAL_MAX_LINES})")
    if words > JOURNAL_MAX_WORDS:
        problems.append(f"{words} words (max {JOURNAL_MAX_WORDS})")
    if any(l.lstrip().startswith(("#", "-", "*")) for l in lines):
        problems.append("headers/bullets (journal entries are plain prose)")
    if problems:
        die(
            "lenore-docs: journal entry breaks the shape rules: " + "; ".join(problems) + ".",
            "The journal records the arc, not the detail. Trim, or file the detail",
            "as a note (lenore-docs note ...) and mention it here in one clause.",
        )
    name = f"{datetime.now():%Y-%m-%d-%H%M}-{slugify(args.summary, args.topic)}.md"
    path = write_doc(fresh_path(root / "docs/journal", name), args.summary, body)
    print(path.relative_to(root))


def current_branch_slug():
    branch = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return branch.replace("/", "-")


def append_to_section(path, heading, entry_lines):
    """Append entry at the end of the given ## section of project.md."""
    if path.exists():
        lines = path.read_text().splitlines()
    else:
        lines = ["# Project tasks", "", "## Next", "", "## Someday", ""]
    try:
        start = next(i for i, l in enumerate(lines) if l.strip() == heading)
    except StopIteration:
        lines += ["", heading]
        start = len(lines) - 1
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if lines[i].startswith("## "):
            end = i
            break
    while end > start + 1 and not lines[end - 1].strip():
        end -= 1
    lines[end:end] = entry_lines
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines).rstrip("\n") + "\n")


def cmd_task(root, args, body):
    check_summary(args.summary)
    title = args.summary
    body_lines = [l for l in body.splitlines() if l.strip()] if body else []

    note_rel = None
    if args.note:
        if not body:
            die("lenore-docs: --note needs a body (the backing note's content) via heredoc.")
        name = f"{datetime.now():%Y-%m-%d}-{slugify(title, args.topic)}.md"
        note_path = write_doc(fresh_path(root / "docs/notes", name), title, body)
        note_rel = note_path.relative_to(root / "docs").as_posix()
        body_lines = []
    elif len(body_lines) > TASK_CONTEXT_MAX_LINES:
        die(
            f"lenore-docs: inline task context is {len(body_lines)} lines "
            f"(max {TASK_CONTEXT_MAX_LINES}).",
            "Longer context belongs in a backing note — re-run with --note and the",
            "note is created and linked automatically.",
        )

    entry = f"- {title}"
    if note_rel:
        entry += f" — details: {note_rel}"
    entry_lines = [entry] + [f"  {l}" for l in body_lines]

    if args.branch:
        task_file = root / "docs/tasks" / f"branch-{current_branch_slug()}.md"
        task_file.parent.mkdir(parents=True, exist_ok=True)
        with open(task_file, "a") as f:
            f.write("\n".join(entry_lines) + "\n")
        print(task_file.relative_to(root))
    else:
        task_file = root / "docs/tasks/project.md"
        heading = "## Someday" if args.someday else "## Next"
        append_to_section(task_file, heading, entry_lines)
        print(f"{task_file.relative_to(root)} ({heading[3:]})")
    if note_rel:
        print(f"docs/{note_rel}")


EXPERIMENT_README = """\
---
status: exploring
question: {question}
verdict:
---

# {title}

## Question
{question}

---
History: notebook/ — catch up with `cat notebook/*.md`
"""


def cmd_experiment(root, args, body):
    check_summary(args.summary)
    dirname = f"{datetime.now():%Y-%m-%d}-{slugify(args.summary, args.topic)}"
    exp = root / "experiments" / dirname
    if exp.exists():
        die(f"lenore-docs: {exp.relative_to(root)} already exists.")
    store = root / "data" / "experiments" / dirname
    (exp / "notebook").mkdir(parents=True)
    for d in ("regen", "keep", "out"):
        (store / d).mkdir(parents=True, exist_ok=True)
    question = args.question or args.summary
    (exp / "README.md").write_text(
        EXPERIMENT_README.format(title=args.summary, question=question))
    (exp / "data").symlink_to(f"../../data/experiments/{dirname}")
    print(exp.relative_to(root))
    print(f"data/experiments/{dirname}/{{regen,keep,out}}")
    print("Fill README's Question (and Data once data exists); commit the dir",
          file=sys.stderr)
    print("and the data symlink. Templates: doc-system skill, references/experiment-templates.md.",
          file=sys.stderr)


def resolve_experiment(root, name):
    exp_root = root / "experiments"
    if (exp_root / name).is_dir():
        return name
    hits = [p.name for p in sorted(exp_root.glob("*/"))
            if p.is_dir() and name in p.name]
    if len(hits) == 1:
        return hits[0]
    if not hits:
        die(f"lenore-docs: no experiments/*{name}* directory found.")
    die(f"lenore-docs: '{name}' is ambiguous: " + ", ".join(hits))


def cmd_run(root, args, body):
    dirname = resolve_experiment(root, args.experiment)
    exp = root / "experiments" / dirname
    out_root = root / "data" / "experiments" / dirname / "out"
    ids = [0]
    for d in (exp / "notebook", out_root):
        if d.exists():
            for p in d.iterdir():
                m = re.match(r"run(\d+)", p.name)
                if m:
                    ids.append(int(m.group(1)))
    runid = f"run{max(ids) + 1:03d}"
    if args.slug:
        runid += "-" + slugify(args.slug, None)
    out_dir = out_root / runid
    out_dir.mkdir(parents=True)   # reserving the id IS the point — fail if taken
    print(f"reserved: data/experiments/{dirname}/out/{runid}/  (write all outputs here)")
    print(f"record:   experiments/{dirname}/notebook/{runid}.md  (when the run means something)")
    print("Entry shape: '# {} — {:%Y-%m-%d}' header; one-sentence outcome; command:/commit:/"
          .format(runid, datetime.now()), file=sys.stderr)
    print("inputs:/outputs: anchors; '## What happened' + '## Interpretation' prose.",
          file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(prog="lenore-docs", add_help=True,
                                     description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("note", "bug", "journal", "task"):
        p = sub.add_parser(name)
        p.add_argument("summary", help="one-line summary (becomes line 1 / the task title)")
        p.add_argument("--topic", help="filename slug override")
        p.add_argument("--body-file", help="read body from a file instead of stdin")
        if name == "note":
            p.add_argument("--supersedes", help="older note this one revises (notes/... or docs/notes/...)")
        if name == "task":
            p.add_argument("--someday", action="store_true", help="file under ## Someday instead of ## Next")
            p.add_argument("--branch", action="store_true", help="append to this branch's task file instead of project.md")
            p.add_argument("--note", action="store_true", help="body becomes a backing note in docs/notes/, auto-linked")
    p = sub.add_parser("experiment")
    p.add_argument("summary", help="short experiment name (becomes the dated dir slug and README title)")
    p.add_argument("--question", help="one-line question for the README front-matter (defaults to the name)")
    p.add_argument("--topic", help="dir slug override")
    p = sub.add_parser("run")
    p.add_argument("experiment", help="experiment dir name, or a unique substring of it")
    p.add_argument("slug", nargs="?", help="optional run slug (runNNN-<slug>)")
    args = parser.parse_args()

    root = repo_root()
    body = read_body(args) if args.cmd not in ("experiment", "run") else ""
    {"note": cmd_note, "bug": cmd_bug, "journal": cmd_journal, "task": cmd_task,
     "experiment": cmd_experiment, "run": cmd_run}[args.cmd](root, args, body)


if __name__ == "__main__":
    main()
