# Orchestration and deployment proposal

## Chosen coordinator: dbt Cloud jobs

Use the already-assumed dbt Cloud capability for Git-backed environments, CI artifacts and scheduled transformations. This avoids introducing Dagster solely for a 2–3-hour assessment. An external readiness check can trigger a job after connector health/sync completion; the exact API implementation depends on credentials, connector tooling and accounts that were not supplied.

## Proposed cadence, not a measured SLA

Ops attempts and fincrime/task operational facts: target hourly after CDC readiness, with non-overlapping runs. Finance: authoritative daily job after the previous UTC day and approved FX rates are available; an optional hourly local-currency provisional view should be labelled provisional, not silently marketed as reconciled USD Finance data. Growth POC: on demand, or once daily after a confirmed post-06:00 Fivetran sync while actively evaluating the funnel. Never schedule the 100M-event source hourly for this POC. Small reference policy seeds change only through reviewed code.

The delivered full-refresh production baseline must be benchmarked before asserting that hourly execution at the supplied volumes is affordable. If it misses the budget, reduce cadence transparently while implementing a validated changed-key feed; do not activate unsafe incrementality to conceal a performance issue.

## Stable reads and publication

Choose a source-readiness boundary, record connector watermarks and create/use an approved stable warehouse snapshot or equivalent versioned inputs. A warehouse snapshot makes warehouse reads repeatable, but does not create cross-service transactional completeness. Orphan checks and observed lag remain necessary.

Build in a versioned candidate namespace, validate types, keys, relationships, distributions, FX coverage and golden metrics, then promote through a reviewed serving mechanism. Keep last-known-good consumer views/release and rollback artifacts. `dbt build` alone is not an atomic transaction for the whole DAG. A sequence of ALTER VIEW statements is not an atomic whole-release switch either; choose a release-level routing/swap mechanism the platform supports and test it before relying on it.

## Pull requests

Run local tests, native dbt parse and an isolated warehouse CI build. Use a separately retained trusted production manifest with `state:modified+` and deferral when appropriate. The existing PR schema must not resolve to production write targets. Deferral does not automatically change sources: use approved masked/synthetic or scoped read-only inputs. Test both initial and incremental branches where applicable.

A PR review includes the business definition, grain, impacted consumers, test evidence, query profile and before/after numeric comparison. CI must also run quality tests when data changes without code changes; state-based selection alone is insufficient.

## Incremental cutover

Inspect query profiles first. Remove fanout and unnecessary columns; benchmark warehouse runtime, queueing, pruning and spill. Enable the attempt incremental path only after validating its source contracts. Persist checkpoint metadata separately in a real ingestion system; do not conflate maximum business time with a reliable connector checkpoint. Recompute affected keys across joined dimensions for future incremental transaction/rule/task models. Plan deletes, late changes, replay and schema migrations explicitly.

## Monitoring and recovery

Record invocation ID, commit SHA, source snapshot/watermarks, model runtimes, row counts, schema drift, test outcomes, FX gaps, task linkage coverage and consumer freshness. Source-lag or missing-FX incidents should keep the last validated release visible with its timestamp. Retry bounded transient conditions; escalate permanent gaps to the correct owner. Recovery should rebuild/replay from retained source evidence and reconcile by key, currency and day, not only grand totals.

No jobs were created or scheduled by this submission. Planned Hex exposures are declared in YAML but no dashboard was published.
