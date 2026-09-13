# Validation record

Environment: macOS, Python 3.12 via `uv` (`uv.lock` unchanged), dbt-core 1.12.4, dbt-duckdb 1.10.1, dbt-snowflake 1.10.8,
dbt-metricflow 0.14.0. Local DuckDB only. No Snowflake credentials; nothing executed on Snowflake.

| Step | Command | Outcome |
|------|---------|---------|
| Install from lockfile | `uv sync` | ok, no changes |
| Clean rebuild | `uv run dbt clean` then `make build` | `Done. PASS=201 WARN=0 ERROR=0 SKIP=0 NO-OP=7 TOTAL=208` |
| Data + unit tests | included in build | 135 generic, 23 singular, 4 unit tests, all pass |
| Semantic validation | `uv run mf validate-configs` | 6 stages, `ERRORS: 0` each |
| Five metrics | `make metrics` | rows returned for all five |
| Late-arrival regression | `uv run python scripts/test_late_arrival.py` | 6 PASS: insert of historical key, reporting date unchanged, correction applied, key unique, row count +1, idempotent rerun; cleanup restores baseline |
| Missing-FX regression | `uv run python scripts/test_missing_fx_metric.py` | 7 PASS through `mf query`: all valid 260; one missing null (local 150); all missing null; two groups only incomplete null; combined null; excluded row ignored; filter restores 130 |
| Lint | `uv run sqlfluff lint models tests analyses` | clean |
| Snowflake-target parse | `uv run dbt parse --target prod --no-partial-parse` | 0 errors, 0 deprecations |
| Fresh clone | `git clone` into empty dir, `uv sync`, `make build`, `make regress`, `make metrics` | see final row after packaging |
| GitHub Actions | `.github/workflows/ci.yml` | configured; not observed running on a hosted runner |
| PDF | `docs/01_architecture.pdf` rendered with xhtml2pdf, read back | 3 pages, tables intact, no clipping |

Environment limitations: no Snowflake account, so contracts, MERGE semantics, numeric precision and clustering are
parsed but not executed. `mf query` runs against DuckDB.

Unresolved risks: Snowflake runtime not exercised; delete propagation into already-merged incremental facts needs a
full refresh; FX or policy restatements need an explicit full refresh of `fct_transactions`; snapshot captures
run-time states only; the StreamServe landing shape is an assumption until the connector config is seen.
