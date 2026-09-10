# AI prompt log and implementation judgment

## Tool use

ChatGPT was used to read the supplied assessment, map requirements to models, draft SQL/YAML/documentation, generate synthetic fixtures and inspect test failures. Local Python, Jinja2, PyYAML, SQLite and pytest were used for structural and synthetic SELECT checks. Official dbt documentation was consulted for implementation context. ReportLab and Graphviz were used for deterministic document/diagram artifacts. No NALA warehouse, dbt Cloud project, Hex workspace or private repository was queried or modified.

## Direction given

The candidate asked for an end-to-end implementation and explanation, then explicitly requested code/files/documents when earlier image-only outputs failed to deliver them. The substantive implementation was grounded in `AnalyticsTask2026-1.0.md`, with a separate learning pack so the submission stays concise.

## Decisions and corrections made during assisted implementation

- Translate every supplied table into a documented stage, not a generic invented schema.
- Do not pretend the sent-to-received exchange_rate converts to USD. Declare a Finance-approved rate dependency and fail on missing conversion coverage; prevent partial USD totals.
- Count outbound transactions separately from attempts. Keep incoming/collection-only/conversion-only/reward/reversal types out of the policy and explicitly state the outgoing-P2P interpretation.
- Keep all formal review records, including inconclusive and repeat reviews, because that is the required denominator. Preserve exact rule versions rather than joining the newest definition by name.
- Preserve ambiguous/unmatched tasks and label single-candidate links as inferred. Do not manufacture a causal execution key or select an arbitrary nearest match.
- Do not equate every KYC step with complete KYC. Require a clearly labelled proposed final-step signal and preserve the independent signup-to-first-transaction metric.
- Do not invent CDC ingestion metadata or use business timestamps as connector freshness. Keep unsafe incremental execution disabled by default.
- During local test execution, a Snowflake `::timestamp_ntz` cast was initially left in an incremental branch by the SQLite compatibility helper. The helper was corrected, and the suite was rerun. This was a local-harness correction, not a claim of fixing a Snowflake production incident.

## Validation limits

The package records actual local results separately. Native dbt installation was attempted but failed because package-host network/DNS access was unavailable. Native dbt parsing, MetricFlow compilation, Snowflake execution/MERGE and live cost benchmarks were not completed. The local SQLite tests are not represented as equivalent to these checks.

## Candidate review

This log describes the observable AI-assisted workflow. It does not claim that Karan independently wrote the code, personally overrode specific outputs, reviewed every model already, or spent a particular number of focused hours. Before submission, the candidate should read the architecture, approve or revise the assumptions, rerun available checks and be able to explain the chosen grains and failure modes. Any further human edits should be added to this log factually.
