# Validation report

Run date: 7 September 2026. These results describe the delivered files, not a NALA production environment.

## Results actually obtained

| Check | Observed result | Scope |
|---|---|---|
| Project structural/Jinja check | PASS | 32 model definitions; all 15 supplied source-table stages; no missing model documentation or unresolved declared references in the checked SQL |
| Documented model interface | 377 columns | Each model column has a description and data type; 90 column-level test declarations plus model-level grain checks |
| Synthetic regression suite | **25 passed** | Local Python/SQLite harness; final run 3.94 seconds |
| Actual model SELECT bodies evaluated | 31 | SQL read from the delivered model files, rendered with local Jinja helpers and adapted to SQLite |
| Calendar utility | Local equivalent supplied | Snowflake GENERATOR itself was not executed |
| Singular SQL tests | 23 exercised on the clean fixture | Adversarial cases also verify selected failure assertions actually fire |
| Native dbt unit definitions supplied | 4 | Not executed natively; corresponding behaviours are represented by local tests |
| MetricFlow structural definitions | 6 semantic models; 11 metrics | Five required named metrics and six ratio helper metrics; structure/reference check, not native MetricFlow compilation |
| Documents | 3-page architecture and separate 14-page walkthrough | PDFs rendered and visually inspected; editable Markdown and diagram source included |

Evidence is in `validation_evidence/`: structural JSON, pytest output, JUnit XML, local environment versions and synthetic demo row counts. The fixtures contain no real customer data or approved exchange rates.

## What the SQL harness does

`validation/harness.py` reads the repository's model SQL, resolves `ref`/`source` and project macros using a limited Jinja context, and evaluates the SELECT bodies in dependency order. It supplies scalar compatibility functions for operations such as JSON access, timestamps and array membership and adapts Snowflake casts. It checks output column names against documented model interfaces.

The tests exercise model joins, grouping, filters, windows, denominator choices, event ordering, and explicit unknown/ambiguous cases. They do not replace warehouse integration testing. SQLite typing and decimal arithmetic differ from Snowflake. The optional incremental SELECT branch is evaluated, but its native MERGE statement, materialisation and transaction semantics are not.

## Important adversarial checks

Missing GBP conversion rates produce NULL USD totals and coverage failures rather than partial sums. Duplicate FX keys expose fan-out. Attempt denominators retain pending records and all latency boundaries are checked. Formal reviews include INCONCLUSIVE and repeated review rows; retired rule versions stay attached to historical executions. Workflow candidates preserve ambiguity and reject future/wrong-scope matches. Shared-device anonymous events remain unresolved. Missing final-KYC flags remain visible without changing the independent signup-to-first-transaction duration metric. Malformed JSON is detected. A recently updated old attempt is selected by the incremental branch.

## Not performed or not established

- Native dbt dependency installation, parsing or warehouse execution. Installation was attempted but package-host DNS/network access failed; native parse remains pending.
- Native MetricFlow validation, SQL generation, live semantic-layer queries or Hex integration.
- Snowflake contracts, roles/grants, physical table creation, MERGE, CDC checkpointing, numeric precision, query profiles, costs or latency benchmarks.
- Source connector configuration, exact ingestion metadata, replica consistency, hard-delete semantics or the real Fivetran sync-completion signal.
- Approved Finance FX rates, exact terminal timestamps, a causal task/workflow key or final-KYC instrumentation.
- Any email, private GitHub repository creation, job scheduling, dashboard publication or production change.

## Release gates

The assessment explicitly allows a project that need not be runnable. Nonetheless, before operational use: confirm source contracts and raw schema mappings; populate the approved FX dependency; approve metric and attribution assumptions; run native dbt parse and MetricFlow checks for the chosen versions; run unit/data/contract tests in an isolated Snowflake environment; validate both initial and incremental states; benchmark representative volumes; configure least-privilege access and connector health; then test the versioned publication and rollback process.

Candidate review of all material is required before submission. AI use and corrections are described factually in `03_AI_Prompt_Log.md`.
