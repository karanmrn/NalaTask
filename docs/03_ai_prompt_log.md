# AI prompt log

How I used AI on this assessment, what I asked for, and where I overruled it.

## Tools

- ChatGPT (GPT-6, chat interface) for the first pass: reading the brief, proposing the model graph, drafting SQL, YAML and the architecture text.
- Claude Code (Claude, terminal agent) for the second pass: auditing the draft against the brief, making the project runnable, rebuilding the weak parts, writing the docs with me.

## Pass 1: ChatGPT, first draft

I gave it the brief and asked for the complete project: every source table staged, marts for the four requirements, one exploratory model, MetricFlow YAML, docs, tests. I asked it to state every assumption instead of filling gaps silently.

What it got right and I kept: the grain per requirement (transaction, attempt, formal review, task), all-states denominators for provider success and false positive rate, the outbound type policy as a seed rather than a SQL `IN` list, joining rule executions to the exact rule version, keeping ambiguous task matches visible, the Amplitude branch isolated from production.

What I rejected:

1. It could not run dbt (no network in its sandbox), so it built a Python/SQLite harness that re-implemented dbt's ref/source resolution and ran the models on fake tables. Three thousand lines of scaffolding that a reviewer would have to trust. Deleted.
2. It refused to deduplicate CDC rows ("no ordering column supplied") and assumed a merged current-state replica. That dodges the question the brief asks. Replaced with an explicit change-log assumption and a dedupe macro with a one-variable switch.
3. It made every fact a full table rebuild and shipped the only incremental path disabled "until contracts are validated". For 30M-row tables on a role about cost reduction that is not a plan. Replaced with incremental merge on `updated_at` with a lookback, plus a state snapshot.
4. Finance volume was on creation date because "no completed_at is supplied". The snapshot gives one; `updated_at` on a `COMPLETED` row is the fallback. Volume now sits on completion date, success rate on creation cohort.
5. The FX join required an exact date match, so a weekend nulled the whole day's USD total. Replaced with latest rate on or before the date, bounded at 7 days, with the age exposed.
6. The prose. Every paragraph hedged ("not a claim of", "candidate review is required"). I rewrote the architecture and README to state decisions and put the uncertainty in one assumptions table.
7. Contracts declared `number(38,0)` for columns the SQL produced as `NUMBER(1,0)`. That fails on Snowflake. Found by reading, not by running; fixed by making contracts Snowflake-only and typing explicitly.

## Pass 2: Claude Code, make it real

Directed to: import the draft into a fresh git repo, get `dbt parse` and then `dbt build` green on DuckDB with synthetic data, then apply the changes above, then keep the docs honest.

Things it found that I would have missed: `try_parse_json` and `array_contains` have no DuckDB equivalent, so the adapter-dispatch macros exist; the seed loader raced the staging models because sources have no dependency on seeds (`make build` seeds first); `row_number` got renamed to `row_decimal` by my own global replace (caught by the build, fixed in a minute).

Things I overruled: it wanted a Snowflake trial account to prove the build. The brief says the project need not run; DuckDB plus `dbt parse --target prod` covers the parse and execution risk without a second environment. It wanted to keep the GPT walkthrough guide in the submission; that is interview prep, not a deliverable.

## What I did myself

Chose the grains and denominators. Decided the two finance time axes. Wrote the assumptions table. Read every model once before sending. Ran `make build`, `make metrics`, `make lint` on the final commit.

Total time on the deliverables: about three hours across two sessions, most of it reviewing and deciding rather than typing.
