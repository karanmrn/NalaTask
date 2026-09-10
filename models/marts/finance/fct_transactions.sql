{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='transaction_id',
    on_schema_change='append_new_columns',
    cluster_by=['transaction_date']
) }}

-- One row per transaction. Volume-qualifying flag from the seed policy; USD via the approved
-- daily rate (latest rate on or before the transaction date, at most fx_max_staleness_days old).

with transactions as (
    select *
    from {{ ref('int_transactions_classified') }}
    {{ incremental_lookback('updated_at') }}
),

rates as (
    select * from {{ ref('stg_reference__daily_fx_rates') }}
),

fx_candidates as (
    select
        t.transaction_id,
        r.rate_date as fx_rate_date,
        r.usd_per_unit,
        r.rate_source,
        row_number() over (partition by t.transaction_id order by r.rate_date desc) as recency_rank
    from transactions as t
    inner join rates as r
        on
            t.sent_currency = r.currency
            and t.transaction_date >= r.rate_date
            and r.rate_date >= {{ dbt.dateadd('day', '-' ~ var('fx_max_staleness_days', 7), 't.transaction_date') }}
),

fx as (
    select * from fx_candidates
    where recency_rank = 1
),

joined as (
    select
        t.*,
        case when t.sent_currency = 'USD' then t.transaction_date else fx.fx_rate_date end as fx_rate_date,
        case when t.sent_currency = 'USD' then cast(1 as decimal(38, 12)) else fx.usd_per_unit end as usd_per_unit,
        case when t.sent_currency = 'USD' then 'USD_IDENTITY' else fx.rate_source end as fx_rate_source
    from transactions as t
    left join fx on t.transaction_id = fx.transaction_id
)

select
    transaction_id,
    user_id,
    account_id,
    transaction_type,
    transaction_state,
    sent_amount,
    sent_currency,
    received_currency,
    created_at,
    updated_at,
    completed_at,
    transaction_date,
    completed_date,
    currency_corridor,
    is_volume_qualifying,
    has_unmapped_type,
    qualifying_count,
    completed_qualifying_count,
    completed_sent_amount,
    fx_rate_date,
    {{ dbt.datediff('fx_rate_date', 'transaction_date', 'day') }} as fx_rate_age_days,
    usd_per_unit,
    fx_rate_source,
    case
        when completed_qualifying_count = 0 then cast(0 as decimal(38, 8))
        when usd_per_unit is null or usd_per_unit <= 0 then null
        else cast(completed_sent_amount * usd_per_unit as decimal(38, 8))
    end as completed_sent_amount_usd,
    completed_qualifying_count = 1 and (usd_per_unit is null or usd_per_unit <= 0) as is_missing_fx
from joined
