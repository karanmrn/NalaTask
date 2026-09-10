-- One row per transaction with the outbound-volume policy applied and completion timestamps resolved.
-- completed_at: first COMPLETED transition from the state snapshot when history exists, else the
-- current row's updated_at when the current state is COMPLETED (updated_at is the last state change).

with transactions as (
    select * from {{ ref('stg_payments__transactions') }}
),

policy as (
    select * from {{ ref('transaction_type_policy') }}
),

state_history as (
    select
        transaction_id,
        min(dbt_valid_from) as first_completed_at
    from {{ ref('snap_transaction_state') }}
    where transaction_state = 'COMPLETED'
    group by transaction_id
),

classified as (
    select
        t.transaction_id,
        t.user_id,
        t.account_id,
        t.transaction_type,
        t.transaction_state,
        t.sent_amount,
        t.sent_currency,
        t.received_currency,
        t.created_at,
        t.updated_at,
        case
            when t.transaction_state = 'COMPLETED' then coalesce(h.first_completed_at, t.updated_at)
        end as completed_at,
        cast(t.created_at as date) as transaction_date,
        t.sent_currency || '-' || t.received_currency as currency_corridor,
        coalesce(p.is_volume_qualifying, false) as is_volume_qualifying,
        p.transaction_type is null as has_unmapped_type
    from transactions t
    left join policy p on t.transaction_type = p.transaction_type
    left join state_history h on t.transaction_id = h.transaction_id
)

select
    *,
    cast(completed_at as date) as completed_date,
    case when is_volume_qualifying then 1 else 0 end as qualifying_count,
    case when is_volume_qualifying and transaction_state = 'COMPLETED' then 1 else 0 end as completed_qualifying_count,
    case when is_volume_qualifying and transaction_state = 'COMPLETED' then sent_amount else 0 end as completed_sent_amount
from classified
