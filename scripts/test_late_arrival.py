"""Late-arrival incremental regression for fct_rule_executions (DuckDB dev target).

Scenario, fixed timestamps, isolated to the local database file:
  1. Baseline target exists (run `make build` first).
  2. Two RAW CDC rows land with a recent connector load time:
       a. NEW key `late_new_exec`, created_at 2026-06-01 (far outside any creation-time lookback).
       b. CORRECTION for an existing key: rule_result flipped, same created_at, higher LSN.
  3. `dbt run --select fct_rule_executions` (incremental branch).
  4. Assert: late row present with execution_date 2026-06-01; corrected key shows the new result;
     rule_execution_id unique.
  5. Rerun with no new input; assert identical row count and identical corrected values (idempotent).
  6. Clean up: remove injected RAW rows and full-refresh the model so the database returns to baseline.
Exit code 1 on any failed assertion.
"""
from __future__ import annotations

import subprocess
import sys

import duckdb

DB = "target/nala.duckdb"
LATE_LOADED_AT = "2026-09-08 00:00:00"  # newer than every synthetic _cdc_loaded_at (all on 2026-09-07)
NEW_KEY = "late_new_exec"


def dbt(*args: str) -> None:
    cmd = ["uv", "run", "dbt", "run", "--select", "fct_rule_executions", *args]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-3000:], r.stderr[-1000:])
        raise SystemExit(f"dbt failed: {' '.join(cmd)}")


def q(sql: str):
    con = duckdb.connect(DB, read_only=True)
    try:
        return con.sql(sql).fetchall()
    finally:
        con.close()


def check(cond: bool, msg: str) -> None:
    print(("PASS " if cond else "FAIL ") + msg)
    if not cond:
        raise SystemExit(1)


def main() -> None:
    subprocess.run(["uv", "run", "dbt", "parse", "-q"], check=True)
    baseline_rows = q("select count(*) from analytics_marts.fct_rule_executions")[0][0]
    target_key, old_result, old_created = q(
        "select rule_execution_id, rule_result, created_at from analytics_marts.fct_rule_executions "
        "where rule_result = 'PASS' order by rule_execution_id limit 1"
    )[0]
    template = q(
        f"select rule_id, workflow_execution_id, condition_result, context, started_at, ended_at "
        f"from fincrime.rule_executions where id = '{target_key}' order by _cdc_lsn desc limit 1"
    )[0]
    max_lsn = q("select max(_cdc_lsn) from fincrime.rule_executions")[0][0]

    con = duckdb.connect(DB)
    try:
        cols = "(id, rule_id, workflow_execution_id, result, condition_result, context, created_at, started_at, ended_at, error, review, review_comment, reviewer_id, reviewed_at, _cdc_operation, _cdc_lsn, _cdc_loaded_at)"
        con.execute(
            f"insert into fincrime.rule_executions {cols} values (?, ?, ?, 'FAIL', 'true', ?, '2026-06-01 10:00:00', "
            f"'2026-06-01 10:00:00', '2026-06-01 10:00:01', null, null, null, null, null, 'INSERT', ?, ?)",
            [NEW_KEY, template[0], template[1], template[3], max_lsn + 1, LATE_LOADED_AT],
        )
        con.execute(
            f"insert into fincrime.rule_executions {cols} values (?, ?, ?, 'FAIL', 'true', ?, ?, ?, ?, null, null, null, null, null, 'UPDATE', ?, ?)",
            [target_key, template[0], template[1], template[3], old_created, template[4], template[5], max_lsn + 2, LATE_LOADED_AT],
        )
    finally:
        con.close()

    try:
        dbt()  # incremental run 1
        late = q(f"select execution_date, rule_result, _loaded_at from analytics_marts.fct_rule_executions where rule_execution_id = '{NEW_KEY}'")
        check(len(late) == 1, "late-arriving historical key inserted by incremental run")
        check(str(late[0][0]) == "2026-06-01", f"reporting date stays creation date ({late[0][0]})")
        corrected = q(f"select rule_result, count(*) from analytics_marts.fct_rule_executions where rule_execution_id = '{target_key}' group by 1")
        check(corrected == [("FAIL", 1)], f"existing key corrected from {old_result} to FAIL, still one row")
        dupes = q("select count(*) from (select rule_execution_id from analytics_marts.fct_rule_executions group by 1 having count(*) > 1)")[0][0]
        check(dupes == 0, "rule_execution_id unique after merge")
        rows_after_1 = q("select count(*) from analytics_marts.fct_rule_executions")[0][0]
        check(rows_after_1 == baseline_rows + 1, f"row count {baseline_rows} -> {rows_after_1}")

        dbt()  # incremental run 2, no new input
        rows_after_2 = q("select count(*) from analytics_marts.fct_rule_executions")[0][0]
        corrected2 = q(f"select rule_result, count(*) from analytics_marts.fct_rule_executions where rule_execution_id = '{target_key}' group by 1")
        check(rows_after_2 == rows_after_1 and corrected2 == [("FAIL", 1)], "second run with no new input is idempotent")
    finally:
        con = duckdb.connect(DB)
        con.execute(f"delete from fincrime.rule_executions where _cdc_lsn > {max_lsn}")
        con.close()
        dbt("--full-refresh")
        restored = q(f"select rule_result from analytics_marts.fct_rule_executions where rule_execution_id = '{target_key}'")[0][0]
        print(f"cleanup: injected rows removed, model full-refreshed, {target_key} back to {restored}")


if __name__ == "__main__":
    main()
