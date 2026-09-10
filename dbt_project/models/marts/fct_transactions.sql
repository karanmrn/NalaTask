with rates_applied as (
    select t.*,
        case when t.sent_currency = 'USD' then cast(1 as number(38,12))
             else r.usd_per_unit end as usd_per_unit,
        case when t.sent_currency = 'USD' then 'USD_IDENTITY' else r.rate_source end as fx_rate_source
    from {{ ref('int_transactions_classified') }} t
    left join {{ source('reference_data', 'daily_fx_rates') }} r
      on t.sent_currency = r.currency and t.transaction_date = r.rate_date
      and t.sent_currency <> 'USD'
)
select
    transaction_id, user_id, account_id, transaction_type, transaction_state,
    sent_amount, sent_currency, received_currency, created_at, updated_at,
    transaction_date, currency_corridor, is_volume_qualifying, has_unmapped_type,
    qualifying_count, completed_qualifying_count, completed_sent_amount,
    usd_per_unit, fx_rate_source,
    case when completed_qualifying_count = 0 then cast(0 as number(38,8))
         when usd_per_unit is null or usd_per_unit <= 0 then null
         else cast(completed_sent_amount * usd_per_unit as number(38,8)) end as completed_sent_amount_usd,
    completed_qualifying_count = 1 and (usd_per_unit is null or usd_per_unit <= 0) as is_missing_fx
from rates_applied
