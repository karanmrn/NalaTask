# NALA analytics engineering

## Scope and review route

The authoritative input is `docs/assessment_brief.md`. The delivery is intentionally compact relative to the source graph: one stage per supplied source table; only the intermediates and marts needed for the requirements; explicit model grains and assumptions. The source landing schemas are configurable assumptions (`RAW.PAYMENTS`, `RAW.FINCRIME`, `RAW.AMPLITUDE`).

Read in this order: `docs/ASSUMPTIONS.md` → `models/marts/fct_transactions.sql` → `models/marts/fct_disbursement_attempts.sql` → `models/marts/fct_rule_reviews.sql` → `models/marts/fct_fincrime_tasks.sql` → `models/exploratory/fct_onboarding_funnel.sql` → `models/semantic/metrics.yml`.

## Requirement-to-code map

| Brief requirement | Primary implementation | Consumption model |
|---|---|---|
| 1. Daily completed outbound volume, local and USD | `fct_transactions`, `transaction_type_policy` | `agg_transactions_daily` |
| 2. Attempt-level provider success, durations and bands | `fct_disbursement_attempts` | `agg_provider_daily` |
| 3. Rule volume, false positives and review latency | `fct_rule_executions`, `fct_rule_reviews` | `agg_fincrime_daily` |
| 4. Cross-source fincrime task pipeline | `int_fincrime_task_context`, `int_task_workflow_candidates`, `fct_fincrime_tasks` | `agg_fincrime_tasks_daily` |
| 5. Exploratory ordered onboarding and elapsed hours | `int_onboarding_events`, `fct_onboarding_funnel` | `agg_onboarding_daily` |
| Five required MetricFlow metrics | `models/semantic/metrics.yml` | Six semantic models; five required metrics plus six ratio helper metrics |
| Humans and agents | `AGENTS.md`, `.agents/skills/review-data-change/SKILL.md` | Review gates, bounded tool use, no autonomous publication |

## Local checks without Snowflake

Python 3.11 or later is recommended. In this folder:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-local.txt
python validation/check_project.py
python -m pytest validation -q
python validation/run_demo.py --output-dir ./demo_outputs
```

The harness evaluates the repository's SELECT SQL against synthetic rows using SQLite plus a documented scalar-function/type compatibility layer. Joins, filters, windows and aggregates come from the actual model files. All model column names are checked against YAML. The Snowflake date generator is replaced by an equivalent local calendar.

This does not validate Snowflake numeric precision, query plans, physical materialisations, native MERGE, dbt contracts, dbt unit execution or MetricFlow compilation. Do not label it a successful Snowflake/dbt integration run.

## Native dbt compatibility baseline

The project intentionally uses the classic, measures-based MetricFlow specification requested in the brief, targeting dbt Core 1.10.x. This is not an assertion that Core 1.10 is the newest version. Do not mix this YAML with a different engine's new syntax without a migration and native parse.

```bash
python -m pip install -r requirements.txt
# Native parse only; inert parser profile does not authorise warehouse access.
dbt parse --profiles-dir ci --no-partial-parse
```

Native dependency installation could not be completed in the authoring environment because package-host DNS/network access failed. The native parser step is therefore pending and is included in the GitHub workflow for reproduction in a network-enabled environment.

## Configure a development warehouse

Copy `profiles.yml.example` to a protected `~/.dbt/profiles.yml`, or use a protected profile directory. Populate the environment variables for an approved development account, role, database, warehouse, schema and key-pair identity. Do not commit a populated profile or private key.

Confirm the current-row replica contract and create/populate the approved reference-rate relation described in `operations/reference_fx_contract.sql`. This is a new required dependency, not a fourth source that was supplied by NALA. Its production rates are intentionally absent.

```bash
dbt debug
dbt seed --select transaction_type_policy
dbt build --selector production
dbt build --selector exploratory --vars '{as_of_timestamp: "2026-09-07 12:00:00"}'
dbt docs generate
```

Run the fixed date above only for a reproducible historical review; normal jobs default to their actual execution start time. `dbt docs generate` is not claimed to have run here because it requires the warehouse catalog.

The native dbt unit cases in `models/unit_tests.yml` require dbt and an appropriately configured warehouse. Their local analogues are tested in `validation/`.

## Performance decisions

Staging and the four intermediates are views. Production outputs are persisted, contracted tables. This full-current-snapshot baseline prioritises correctness where source metadata is unspecified; it is NOT a claim that a full hourly rebuild meets latency/cost goals at the stated volumes. Benchmark on representative data before choosing production cadence or compute.

The attempt fact contains an opt-in MERGE path using source `last_updated_at` plus overlap, not transaction creation date. Leave `enable_attempt_incremental: false` until the update timestamp, late-arrival bound and hard-delete contract are confirmed. Even after enabling, keep reconciliation and planned full rebuild/replay. The other facts should gain changed-key processing from a trustworthy connector change feed before high-frequency production operation; a timestamp-only incremental model for `users` would be invented because no update timestamp is supplied.

The exploratory branch materialises only its bounded event subset (90 days by default); downstream POC models are views. It runs on demand, or daily after a confirmed Fivetran sync while an experiment is active. It does not run hourly and cannot delay production jobs.

## Safe serving

`models/exposures.yml` lists planned Hex consumers, not deployed dashboards. Semantic definitions point at facts, not raw JSON or already-aggregated ratios. `analyses/` contains reconciliable SQL reference queries. USD aggregates propagate missing conversion coverage rather than silently returning partial totals. Local-money volume requires currency grouping; MetricFlow YAML alone does not enforce that requirement.

Staging retains the complete supplied source shape and is restricted. Consumption facts exclude recipient names, phone/account numbers, profile images, raw user properties and free-text review/error fields. User IDs remain sensitive pseudonymous identifiers. `store_failures` is disabled so tests do not automatically persist sensitive failure rows.

## Repository layout

- `models/staging/`: all 15 supplied source tables, typed without hiding duplicates.
- `models/intermediate/`: classification, context parsing and candidate joins.
- `models/marts/`: nine production facts/aggregates covering all four requirements.
- `models/exploratory/`: three isolated growth POC models.
- `models/semantic/`: MetricFlow semantic models, required metrics and saved queries.
- `models/utilities/`: configured daily calendar spine.
- `tests/`: singular assertions plus a composite-grain generic test.
- `validation/`: synthetic input fixtures, real-SELECT execution harness and local tests.
- `operations/`: reviewable reference-input and read-only diagnostics SQL.
- `.github/workflows/`: local checks and native parse workflow; no unattended production writes.
- `docs/`: source brief, assumptions, operating plan, source references and agent evaluation cases.

## Repository root and CI

The submission-root `.github/workflows/ci.yml` uses `dbt_project` as the working directory. The workflow inside this folder is for publishing only this folder as the repository root. Keep only the relevant workflow in a deployed repository; no workflow has been dispatched here.
