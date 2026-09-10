-- Hex starting query for cohort success rate. Creation-day cohort, sums before the ratio.
select
    transaction_date,
    currency_corridor,
    sum(qualifying_transactions) as qualifying_transactions,
    sum(completed_transactions) as completed_transactions,
    {{ safe_ratio('sum(completed_transactions)', 'sum(qualifying_transactions)') }} as transaction_success_rate
from {{ ref('agg_transactions_daily') }}
group by transaction_date, currency_corridor
