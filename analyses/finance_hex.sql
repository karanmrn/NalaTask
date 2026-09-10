-- Hex starting query for Finance. Volume on completion date, always grouped by sending currency.
select
    completed_date,
    currency_corridor,
    sent_currency,
    sum(completed_transactions) as completed_transactions,
    sum(completed_sent_amount) as completed_volume_local,
    case
        when sum(missing_fx_transactions) > 0 then null
        else sum(completed_sent_amount_usd)
    end as completed_volume_usd
from {{ ref('agg_finance_volume_daily') }}
group by completed_date, currency_corridor, sent_currency
