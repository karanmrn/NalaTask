# Sources and provenance

Business scope, source columns and required metric wording: the user-provided `AnalyticsTask2026-1.0.md`, copied as `assessment_brief.md`. There is no supplied row-level dataset, approved USD reference series, connector metadata envelope, or direct task/workflow execution foreign key.

Implementation decisions are labelled in `ASSUMPTIONS.md`; synthetic rates/events are labelled in `validation/fixtures.py`. They are not evidence about NALA's business.

Official implementation references checked during preparation (7 September 2026):

- dbt parse: https://docs.getdbt.com/reference/commands/parse
- dbt Snowflake adapter configuration: https://docs.getdbt.com/reference/resource-configs/snowflake-configs
- dbt incremental models: https://docs.getdbt.com/docs/build/incremental-models
- Semantic model definitions: https://docs.getdbt.com/docs/build/semantic-models
- Ratio definitions: https://docs.getdbt.com/docs/build/ratio
- dbt-published explanation of the classic measures-based specification: https://www.getdbt.com/blog/how-the-dbt-semantic-layer-works

The live semantic-model documentation also describes newer specifications. This repository pins a Core 1.10 compatibility baseline and uses the classic semantic_models/measures/type_params structure requested by the assessment; it does not silently mix versions. Native package installation and parser confirmation remain pending because outbound package-network access failed here.
