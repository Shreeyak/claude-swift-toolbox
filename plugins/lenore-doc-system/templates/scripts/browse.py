#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["textual"]
# ///
# usage: uv run scripts/browse.py [group] [--plain] [--json]
# what it does: browses docs/desk, docs/journal, docs/notes, docs/reference,
# docs/tasks, docs/bugs, docs/log, experiments/*/README.md, and scripts/ —
# a TUI by default, or a plain-text/JSON index for agents (--plain/--json
# skip the textual import entirely, so they work without it installed).

from __future__ import annotations

import json
import os
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(
    subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    ).stdout.strip()
    or "."
)

GROUPS = [
    "desk",
    "journal",
    "notes",
    "reference",
    "tasks",
    "bugs",
    "log",
    "experiments",
    "scripts",
]

STALE_DAYS = 14


@dataclass
class Row:
    group: str
    path: str
    date: str
    summary: str
    extra: str = ""
    mtime: float = 0.0


def html_comment_summary(path: Path) -> str:
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return ""
    start = text.find("<!--")
    if start == -1:
        return ""
    end = text.find("-->", start)
    if end == -1:
        return ""
    return text[start + 4 : end].strip()


def md_first_line_summary(path: Path) -> str:
    try:
        with path.open(errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                return line.lstrip("#").strip()
    except OSError:
        pass
    return ""


def script_header_summary(path: Path) -> str:
    try:
        lines = path.read_text(errors="replace").splitlines()[:5]
    except OSError:
        return ""
    for line in lines:
        s = line.strip().lstrip("#").strip()
        if s.startswith("what it does:"):
            return s[len("what it does:") :].strip()
    return ""


def date_from_name(name: str) -> str:
    parts = name.split("-")
    if len(parts) >= 3 and parts[0].isdigit() and len(parts[0]) == 4:
        return "-".join(parts[:3])[:10]
    return ""


def scan_dated_dir(group: str, dirpath: Path) -> list[Row]:
    rows = []
    if not dirpath.is_dir():
        return rows
    for p in sorted(dirpath.glob("*")):
        if p.is_dir() or p.name.startswith("."):
            continue
        summary = (
            html_comment_summary(p) if p.suffix == ".html" else md_first_line_summary(p)
        )
        date = date_from_name(p.stem)
        rows.append(
            Row(
                group=group,
                path=str(p.relative_to(ROOT)),
                date=date,
                summary=summary,
                mtime=p.stat().st_mtime,
            )
        )
    return rows


def scan_desk() -> list[Row]:
    rows = []
    desk = ROOT / "docs" / "desk"
    if not desk.is_dir():
        return rows
    import time

    now = time.time()
    for link in sorted(desk.iterdir()):
        if not link.is_symlink():
            continue
        target_exists = link.exists()
        mtime = link.lstat().st_mtime
        age_days = (now - mtime) / 86400
        flags = []
        if not target_exists:
            flags.append("dangling")
        elif age_days >= STALE_DAYS:
            flags.append(f"stale({int(age_days)}d)")
        resolved = link.resolve() if target_exists else None
        summary = ""
        if resolved and resolved.is_file():
            summary = (
                html_comment_summary(resolved)
                if resolved.suffix == ".html"
                else md_first_line_summary(resolved)
            )
        rows.append(
            Row(
                group="desk",
                path=str(link.relative_to(ROOT)),
                date="",
                summary=summary,
                extra=",".join(flags),
                mtime=mtime,
            )
        )
    return rows


def scan_experiments() -> list[Row]:
    rows = []
    exp_dir = ROOT / "experiments"
    if not exp_dir.is_dir():
        return rows
    for readme in sorted(exp_dir.glob("*/README.md")):
        status = ""
        verdict = ""
        try:
            text = readme.read_text(errors="replace")
        except OSError:
            text = ""
        if text.startswith("---"):
            end = text.find("---", 3)
            fm = text[3:end] if end != -1 else ""
            for line in fm.splitlines():
                if line.strip().startswith("status:"):
                    status = line.split(":", 1)[1].strip()
                if line.strip().startswith("verdict:"):
                    verdict = line.split(":", 1)[1].strip()
        rows.append(
            Row(
                group="experiments",
                path=str(readme.relative_to(ROOT)),
                date="",
                summary=verdict or status,
                extra=status,
                mtime=readme.stat().st_mtime,
            )
        )
    return rows


def scan_scripts() -> list[Row]:
    rows = []
    scripts_dir = ROOT / "scripts"
    if not scripts_dir.is_dir():
        return rows
    for p in sorted(scripts_dir.glob("*")):
        if p.is_dir() or p.name.startswith("."):
            continue
        rows.append(
            Row(
                group="scripts",
                path=str(p.relative_to(ROOT)),
                date="",
                summary=script_header_summary(p),
                mtime=p.stat().st_mtime,
            )
        )
    return rows


def scan_tasks() -> list[Row]:
    rows = []
    tasks_dir = ROOT / "docs" / "tasks"
    if not tasks_dir.is_dir():
        return rows
    for p in sorted(tasks_dir.glob("*.md")):
        rows.append(
            Row(
                group="tasks",
                path=str(p.relative_to(ROOT)),
                date="",
                summary=md_first_line_summary(p),
                mtime=p.stat().st_mtime,
            )
        )
    return rows


def collect() -> list[Row]:
    rows: list[Row] = []
    rows += scan_desk()
    rows += scan_dated_dir("journal", ROOT / "docs" / "journal")
    rows += scan_dated_dir("notes", ROOT / "docs" / "notes")
    rows += scan_dated_dir("reference", ROOT / "docs" / "reference")
    rows += scan_tasks()
    rows += scan_dated_dir("bugs", ROOT / "docs" / "bugs")
    rows += scan_dated_dir("log", ROOT / "docs" / "log")
    rows += scan_experiments()
    rows += scan_scripts()
    return rows


def sorted_rows(rows: list[Row]) -> list[Row]:
    return sorted(rows, key=lambda r: r.mtime, reverse=True)


def filter_group(rows: list[Row], group: str | None) -> list[Row]:
    if not group:
        return rows
    return [r for r in rows if r.group == group]


def render_plain(rows: list[Row]) -> str:
    out = []
    for group in GROUPS:
        group_rows = sorted_rows([r for r in rows if r.group == group])
        if not group_rows:
            continue
        out.append(f"── {group} ({len(group_rows)}) " + "─" * max(0, 40 - len(group)))
        for r in group_rows:
            date_col = f"{r.date}  " if r.date else ""
            extra = f"  [{r.extra}]" if r.extra else ""
            out.append(f"{date_col}{Path(r.path).name:<35} {r.summary}{extra}")
    return "\n".join(out)


def render_json(rows: list[Row]) -> str:
    return json.dumps(
        [
            {
                "group": r.group,
                "path": r.path,
                "date": r.date,
                "summary": r.summary,
                "extra": r.extra,
            }
            for r in sorted_rows(rows)
        ],
        indent=2,
    )


def open_in_editor(path: Path) -> None:
    editor = os.environ.get("EDITOR")
    try:
        if editor:
            subprocess.run([editor, str(path)])
        else:
            subprocess.run(["open", str(path)])
    except OSError:
        pass


def run_tui(rows: list[Row], group_filter: str | None) -> None:
    from textual.app import App, ComposeResult
    from textual.widgets import DataTable, Footer, Header

    class BrowseApp(App):
        BINDINGS = [("q", "quit", "Quit")]

        def compose(self) -> ComposeResult:
            yield Header()
            yield DataTable()
            yield Footer()

        def on_mount(self) -> None:
            table = self.query_one(DataTable)
            table.add_columns("group", "date", "file", "summary")
            self._rows = []
            for group in GROUPS:
                for r in sorted_rows(filter_group([r for r in rows if r.group == group], None)):
                    self._rows.append(r)
                    table.add_row(r.group, r.date, Path(r.path).name, r.summary or r.extra)
            table.cursor_type = "row"
            table.focus()

        def on_data_table_row_selected(self, event) -> None:
            idx = event.cursor_row
            if 0 <= idx < len(self._rows):
                open_in_editor(ROOT / self._rows[idx].path)

    BrowseApp().run()


def main() -> None:
    args = sys.argv[1:]
    plain = "--plain" in args
    as_json = "--json" in args
    positional = [a for a in args if not a.startswith("--")]
    group_filter = positional[0] if positional else None

    rows = collect()
    rows = filter_group(rows, group_filter)

    if as_json:
        print(render_json(rows))
        return
    if plain:
        print(render_plain(rows))
        return

    run_tui(rows, group_filter)


if __name__ == "__main__":
    main()
