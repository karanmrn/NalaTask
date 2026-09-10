-- Creation-day cohort of volume-qualifying transactions: how many were created, how many
-- have reached COMPLETED. Success rate is a cohort measure, so the axis is creation date.
-- Recent cohorts restate as in-flight transactions settle.

select
    transaction_date,
    currency_corridor,
    sent_currency,
    transaction_type,
    sum(qualifying_count) as qualifying_transactions,
    sum(completed_qualifying_count) as completed_transactions,
    {{ safe_ratio('sum(completed_qualifying_count)', 'sum(qualifying_count)') }} as transaction_success_rate
from {{ ref('fct_transactions') }}
where is_volume_qualifying
group by 1, 2, 3, 4
