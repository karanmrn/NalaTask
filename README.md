# NALA technical assessment — submission package

Prepared for Karan Manoharan from `AnalyticsTask2026-1.0.md`. Candidate review is still required before submission. This is an AI-assisted implementation, not a claim of independently authored or production-deployed work.

## The three requested deliverables

1. `01_Architecture.pdf` — three pages covering orchestration, materialisations, CDC, joins, quality and semantics. Editable source: `01_Architecture.md`.
2. `dbt_project/` — complete assessment project: 15 source-table staging models, 4 intermediate models, 9 production marts, 3 exploratory models, a calendar spine, documented SQL, semantic definitions, tests, agent guidance and validation scripts.
3. `03_AI_Prompt_Log.md` — tool usage, implementation decisions, corrections and honest validation limits.

The optional deeper teaching material is packaged separately as `NALA_Assessment_Learning.zip`; it is not part of the concise submission.

## Start here

Read the architecture, then `dbt_project/README.md`. Important design decisions and prerequisites are in `dbt_project/docs/ASSUMPTIONS.md`. Exact validation results are in `VALIDATION_REPORT.md`.

The assessment permits a project that need not run. This implementation goes further with a reproducible synthetic SQL harness, but it has NOT been executed in Snowflake, parsed by native dbt, compiled by MetricFlow, deployed to dbt Cloud, or published in Hex. Those are explicit acceptance gates, not claimed achievements.

## Do not hide the missing information

USD reference rates are not provided. Task-to-workflow causal IDs are not provided. Dedicated terminal timestamps are not provided. The final KYC instrumentation contract is not provided. The code exposes these gaps rather than inventing facts.

Only synthetic validation inputs are included; they must never be loaded as real business reference data. No credentials or customer records are included. No repository, dashboard, job or email was created or sent externally.
