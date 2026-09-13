# Local workflow on DuckDB. No credentials required.
.PHONY: setup seed build test lint metrics docs clean

setup:            ## install toolchain
	uv sync
	uv run pre-commit install

seed:             ## regenerate and load synthetic RAW landing tables
	uv run python scripts/generate_synthetic_raw.py
	uv run dbt seed --select path:seeds/raw

build: seed       ## full build: snapshot, models, tests, unit tests
	uv run dbt build --exclude path:seeds/raw

test:             ## tests only
	uv run dbt test

regress:          ## scripted regressions: late-arrival incremental merge, missing-FX semantic guard
	uv run python scripts/test_late_arrival.py
	uv run python scripts/test_missing_fx_metric.py

lint:             ## sqlfluff over models and tests
	uv run sqlfluff lint models tests analyses

metrics:          ## validate semantic layer and query the five required metrics
	uv run mf validate-configs
	uv run mf query --metrics completed_transaction_volume,completed_transaction_volume_usd --group-by metric_time__day,transaction__sent_currency --order -metric_time__day --limit 10
	uv run mf query --metrics transaction_success_rate --group-by metric_time__day,transaction__currency_corridor --limit 10
	uv run mf query --metrics disbursement_provider_success_rate --group-by disbursement_attempt__provider_name
	uv run mf query --metrics fincrime_false_positive_rate --group-by rule_review__rule_name,rule_review__rule_category
	uv run mf query --metrics signup_to_first_transaction_hours --group-by onboarding_entity__signup_country

docs:             ## dbt docs site
	uv run dbt docs generate

clean:
	uv run dbt clean
