"""Missing-FX regression for the semantic metric completed_transaction_volume_usd (DuckDB dev target).

Runs the real MetricFlow query path (`mf query`) against scenario rows injected into
analytics_marts.fct_transactions, isolated by transaction_type = 'ZZ_SCENARIO' and then removed.

Scenarios (GBP 100 at USD 130 is the reference row):
  1. all rows valid FX                      -> USD = full sum
  2. one row missing FX                     -> USD null, local total still known
  3. all rows missing FX                    -> USD null
  4. two corridors, one complete            -> only the incomplete corridor null
  5. both corridors combined in one total   -> null
  6. missing FX on an excluded (not completed) row -> eligible total unaffected
  7. filter out the incomplete row          -> complete total restored
Exit code 1 on any failed assertion.
"""
from __future__ import annotations

import csv
import subprocess
import sys
import tempfile
from decimal import Decimal
from pathlib import Path

import duckdb

DB = "target/nala.duckdb"
T = "ZZ_SCENARIO"
COLS = ("transaction_id, user_id, account_id, transaction_type, transaction_state, sent_amount, sent_currency, received_currency, "
        "created_at, updated_at, completed_at, transaction_date, completed_date, currency_corridor, is_volume_qualifying, "
        "has_unmapped_type, qualifying_count, completed_qualifying_count, completed_sent_amount, fx_rate_date, fx_rate_age_days, "
        "usd_per_unit, fx_rate_source, completed_sent_amount_usd, is_missing_fx, missing_fx_count")


def row(tid, corridor, sent, usd, completed=True, day="2026-09-01"):
    cur = corridor.split("-")[0]
    missing = usd is None and completed
    state = "COMPLETED" if completed else "EXPIRED"
    cq = 1 if completed else 0
    return (tid, "u", "a", T, state, sent, cur, corridor.split("-")[1], f"{day} 10:00:00", f"{day} 11:00:00",
            f"{day} 11:00:00" if completed else None, day, day if completed else None, corridor, True, False, 1, cq,
            sent if completed else 0, None if missing else day, None if missing else 0, None if missing else Decimal("1.3"),
            None if missing else "TEST", None if (missing or not completed) else usd, missing, 1 if missing else 0)


SCENARIOS = {
    # name: (rows, group_by, where, expected {group: (local, usd)})
    "1_all_valid": ([row("s1a", "GBP-KES", 100, 130), row("s1b", "GBP-KES", 100, 130)], None, None, {(): (200, 260)}),
    "2_one_missing": ([row("s2a", "GBP-KES", 100, 130), row("s2b", "GBP-KES", 50, None)], None, None, {(): (150, None)}),
    "3_all_missing": ([row("s3a", "GBP-KES", 100, None), row("s3b", "GBP-KES", 50, None)], None, None, {(): (150, None)}),
    "4_two_groups": ([row("s4a", "GBP-KES", 100, 130), row("s4b", "EUR-TZS", 100, 110), row("s4c", "EUR-TZS", 50, None)],
                     "transaction__currency_corridor", None, {("GBP-KES",): (100, 130), ("EUR-TZS",): (150, None)}),
    "5_combined_total": ([row("s5a", "GBP-KES", 100, 130), row("s5b", "EUR-TZS", 50, None)], None, None, {(): (150, None)}),
    "6_excluded_row_missing": ([row("s6a", "GBP-KES", 100, 130), row("s6b", "GBP-KES", 50, None, completed=False)], None, None, {(): (100, 130)}),
    "7_filter_restores": ([row("s7a", "GBP-KES", 100, 130), row("s7b", "GBP-KES", 50, None, day="2026-09-02")], None,
                          "{{ TimeDimension('metric_time', 'day') }} = '2026-09-01'", {(): (100, 130)}),
}


def mf_query(group_by, where):
    out = Path(tempfile.mkdtemp()) / "out.csv"
    cmd = ["uv", "run", "mf", "query", "--metrics", "completed_transaction_volume,completed_transaction_volume_usd",
           "--where", "{{ Dimension('transaction__transaction_type') }} = '" + T + "'" + (" AND " + where if where else ""),
           "--csv", str(out)]
    if group_by:
        cmd += ["--group-by", group_by]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-2000:], r.stderr[-2000:]); raise SystemExit("mf query failed")
    with out.open() as f:
        return list(csv.DictReader(f))


def num(v):
    return None if v in ("", None) else Decimal(v)


def main():
    # Semantic manifest must describe the dev target (a prior `dbt parse --target prod` would point mf at Snowflake).
    subprocess.run(["uv", "run", "dbt", "parse", "-q"], check=True)
    con = duckdb.connect(DB)
    con.execute(f"delete from analytics_marts.fct_transactions where transaction_type = '{T}'")
    con.close()
    failed = 0
    for name, (rows, group_by, where, expected) in SCENARIOS.items():
        con = duckdb.connect(DB)
        con.executemany(f"insert into analytics_marts.fct_transactions ({COLS}) values ({','.join('?' * 26)})", rows)
        con.close()
        try:
            result = mf_query(group_by, where)
            got = {}
            for r in result:
                key = (r.get("transaction__currency_corridor") or r.get("currency_corridor"),) if group_by else ()
                got[key] = (num(r["completed_transaction_volume"]), num(r["completed_transaction_volume_usd"]))
            ok = {k: (Decimal(v[0]), None if v[1] is None else Decimal(v[1])) for k, v in expected.items()} == got
            print(("PASS " if ok else "FAIL ") + f"{name}: expected {expected} got {got}")
            failed += 0 if ok else 1
        finally:
            con = duckdb.connect(DB)
            con.execute(f"delete from analytics_marts.fct_transactions where transaction_type = '{T}'")
            con.close()
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
