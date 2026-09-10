{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='attempt_id',
    on_schema_change='append_new_columns',
    cluster_by=['attempt_date']
) }}

-- One row per disbursement attempt. Provider is the attempt's own provider, not the parent
-- disbursement's final provider. Durations are creation to last state change for terminal states.

with attempts as (
    select
        attempt_id, disbursement_id, attempt_state, provider_name, selection_reason,
        provider_error_category, created_at, updated_at, eta, max_eta
    from {{ ref('stg_payments__disbursement_attempts') }}
    {{ incremental_lookback('updated_at') }}
),

measured as (
    select
        *,
        cast(created_at as date) as attempt_date,
        1 as attempt_count,
        case when attempt_state = 'COMPLETED' then 1 else 0 end as completed_attempt_count,
        case when attempt_state = 'FAILED' then 1 else 0 end as failed_attempt_count,
        case when attempt_state = 'COMPLETED' and updated_at >= created_at
             then {{ dbt.datediff('created_at', 'updated_at', 'millisecond') }} / 1000.0 end as completion_seconds,
        case when attempt_state = 'FAILED' and updated_at >= created_at
             then {{ dbt.datediff('created_at', 'updated_at', 'millisecond') }} / 1000.0 end as failure_seconds
    from attempts
)

select
    attempt_id,
    disbursement_id,
    attempt_state,
    provider_name,
    selection_reason,
    provider_error_category,
    created_at,
    updated_at,
    eta,
    max_eta,
    attempt_date,
    attempt_count,
    completed_attempt_count,
    failed_attempt_count,
    cast(completion_seconds as decimal(38,6)) as completion_seconds,
    cast(failure_seconds as decimal(38,6)) as failure_seconds,
    {{ latency_band('completion_seconds') }} as completion_time_band
from measured
