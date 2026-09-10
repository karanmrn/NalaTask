-- Finance daily view: completed outbound volume by completion date, corridor and type.
-- Time axis is completed_date (when the money moved), not the creation date.
-- USD total is null for the whole group when any transaction in it lacks an approved rate:
-- a partial USD sum is worse than no USD sum.

select
    completed_date,
    currency_corridor,
    sent_currency,
    received_currency,
    transaction_type,
    sum(completed_qualifying_count) as completed_transactions,
    sum(completed_sent_amount) as completed_sent_amount,
    sum(case when is_missing_fx then 1 else 0 end) as missing_fx_transactions,
    case
        when sum(case when is_missing_fx then 1 else 0 end) > 0 then null
        else sum(completed_sent_amount_usd)
    end as completed_sent_amount_usd,
    max(fx_rate_age_days) as max_fx_rate_age_days
from {{ ref('fct_transactions') }}
where
    is_volume_qualifying
    and completed_qualifying_count = 1
group by 1, 2, 3, 4, 5
