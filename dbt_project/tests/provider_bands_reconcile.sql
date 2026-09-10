{{ config(severity='error', tags=['ops']) }}
select attempt_date from {{ ref('agg_provider_daily') }} where completed_attempts <> under_1_min + from_1_to_5_min + from_5_to_30_min + from_30_min_to_1_hour + from_1_to_24_hours + over_24_hours + completed_duration_unknown
