{{ config(materialized='incremental' if var('enable_attempt_incremental', false) else 'table',
          incremental_strategy='merge', unique_key='attempt_id', on_schema_change='fail') }}
with changed as (
    select attempt_id, disbursement_id, attempt_state, provider_name,
           selection_reason, provider_error_category, created_at, updated_at, eta, max_eta
    from {{ ref('stg_payments__attempts') }}
    {% if is_incremental() %}
    where coalesce(updated_at, created_at) >= (
        select dateadd('day', -{{ var('incremental_overlap_days', 3) }},
                       coalesce(max(coalesce(updated_at, created_at)), '1900-01-01'::timestamp_ntz))
        from {{ this }}
    )
    {% endif %}
), durations as (
    select *,
        cast(created_at as date) as attempt_date,
        1 as attempt_count,
        case when attempt_state = 'COMPLETED' then 1 else 0 end as completed_attempt_count,
        case when attempt_state = 'FAILED' then 1 else 0 end as failed_attempt_count,
        case when attempt_state = 'COMPLETED' and updated_at >= created_at
             then datediff('millisecond', created_at, updated_at) / 1000.0 end as completion_seconds_proxy,
        case when attempt_state = 'FAILED' and updated_at >= created_at
             then datediff('millisecond', created_at, updated_at) / 1000.0 end as failure_seconds_proxy
    from changed
)
select
    attempt_id, disbursement_id, attempt_state, provider_name, selection_reason,
    provider_error_category, created_at, updated_at, eta, max_eta, attempt_date,
    attempt_count, completed_attempt_count, failed_attempt_count,
    completion_seconds_proxy, failure_seconds_proxy,
    {{ latency_band('completion_seconds_proxy') }} as completion_time_band
from durations
