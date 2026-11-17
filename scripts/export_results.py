#!/usr/bin/env python3
"""
Run every query in sql/04_basic_queries.sql and save its output to results/*.csv,
so the findings can be read on GitHub without setting up a database.

Usage (from the repository root, after sql/00_run_all.sql has been run):
    python3 scripts/export_results.py -u root
Any arguments are passed on to the mysql client (user, host, port ...).
Put the password in ~/.my.cnf or the MYSQL_PWD environment variable so you
are not prompted once per query.
"""
import csv
import io
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
mysql_args = sys.argv[1:]
sql = (ROOT / "sql" / "04_basic_queries.sql").read_text(encoding="utf-8")

# split on the "-- Qn." headers; a section may hold more than one statement
sections = re.split(r"\n(?=-- Q\d+\.)", sql)
out_dir = ROOT / "results"
out_dir.mkdir(exist_ok=True)

for section in sections:
    header = re.match(r"-- (Q\d+)\. ([^\n]+)", section)
    if not header:
        continue
    qid, title = header.group(1), header.group(2).rstrip(" -")
    slug = re.sub(r"[^a-z0-9]+", "_", title.lower()).strip("_")[:45].rstrip("_")
    statements = [s.strip() for s in section.split(";") if re.search(r"\bSELECT\b", s, re.I)]
    for i, stmt in enumerate(statements, start=1):
        suffix = f"_{i}" if len(statements) > 1 else ""
        target = out_dir / f"q{int(qid[1:]):02d}_{slug}{suffix}.csv"
        result = subprocess.run(["mysql", *mysql_args, "--batch", "--raw", "-D", "inventory_basics", "-e", stmt],
                                capture_output=True, text=True, check=True)
        rows = [line.split("\t") for line in result.stdout.splitlines()]
        rows = [["" if v == "NULL" else v for v in r] for r in rows]
        buf = io.StringIO()
        csv.writer(buf, lineterminator="\n").writerows(rows)
        target.write_text(buf.getvalue(), encoding="utf-8")
        print(f"{target.relative_to(ROOT)}  ({len(rows) - 1} rows)")
