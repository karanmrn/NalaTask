{{ config(severity='error', tags=['ops']) }}
select attempt_date from {{ ref('agg_provider_daily') }} where provider_success_rate < 0 or provider_success_rate > 1 or completed_attempts > attempts
