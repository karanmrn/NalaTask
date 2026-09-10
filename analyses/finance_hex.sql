-- Mandatory local-money currency grouping. This mirrors the semantic definition.
select
    transaction_date,
    currency_corridor,
    sent_currency,
    sum(completed_qualifying_count) as completed_transactions,
    sum(completed_sent_amount) as completed_transaction_volume,
    case
        when sum(case when is_missing_fx then 1 else 0 end) > 0 then null
        else sum(completed_sent_amount_usd)
    end as completed_volume_usd,
    {{ safe_ratio('sum(completed_qualifying_count)', 'sum(qualifying_count)') }} as transaction_success_rate
from {{ ref('fct_transactions') }}
where is_volume_qualifying
group by transaction_date, currency_corridor, sent_currency
