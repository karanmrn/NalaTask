select cohort_date, signup_country,
    sum(started_count) as signup_started,
    sum(ordered_signup_count) as signup_completed,
    sum(ordered_kyc_count) as kyc_completed,
    sum(ordered_transaction_count) as transaction_completed,
    {{ safe_ratio('sum(ordered_signup_count)', 'sum(started_count)') }} as start_to_signup_rate,
    {{ safe_ratio('sum(ordered_kyc_count)', 'sum(ordered_signup_count)') }} as signup_to_kyc_rate,
    {{ safe_ratio('sum(ordered_transaction_count)', 'sum(ordered_kyc_count)') }} as kyc_to_transaction_rate,
    avg(case when started_count = 1 then start_to_signup_hours end) as avg_start_to_signup_hours,
    avg(case when ordered_signup_count = 1 then signup_to_kyc_hours end) as avg_signup_to_kyc_hours,
    avg(case when ordered_kyc_count = 1 then kyc_to_transaction_hours end) as avg_kyc_to_transaction_hours
from {{ ref('fct_onboarding_funnel') }}
group by cohort_date, signup_country
