select attempt_date, provider_name,
    sum(attempt_count) as attempts,
    sum(completed_attempt_count) as completed_attempts,
    sum(failed_attempt_count) as failed_attempts,
    {{ safe_ratio('sum(completed_attempt_count)', 'sum(attempt_count)') }} as provider_success_rate,
    avg(completion_seconds) as avg_completion_seconds,
    avg(failure_seconds) as avg_failure_seconds,
    sum(case when completion_time_band = 'UNDER_1_MIN' then 1 else 0 end) as under_1_min,
    sum(case when completion_time_band = '1_TO_5_MIN' then 1 else 0 end) as from_1_to_5_min,
    sum(case when completion_time_band = '5_TO_30_MIN' then 1 else 0 end) as from_5_to_30_min,
    sum(case when completion_time_band = '30_MIN_TO_1_HOUR' then 1 else 0 end) as from_30_min_to_1_hour,
    sum(case when completion_time_band = '1_TO_24_HOURS' then 1 else 0 end) as from_1_to_24_hours,
    sum(case when completion_time_band = 'OVER_24_HOURS' then 1 else 0 end) as over_24_hours,
    sum(case when completed_attempt_count = 1 and completion_seconds is null then 1 else 0 end) as completed_duration_unknown
from {{ ref('fct_disbursement_attempts') }}
group by attempt_date, provider_name
