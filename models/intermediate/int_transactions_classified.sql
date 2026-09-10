select
    t.transaction_id, t.user_id, t.account_id, t.transaction_type,
    t.transaction_state, t.sent_amount, t.sent_currency, t.received_currency,
    t.created_at, t.updated_at,
    cast(t.created_at as date) as transaction_date,
    t.sent_currency || '-' || t.received_currency as currency_corridor,
    coalesce(p.is_volume_qualifying, false) as is_volume_qualifying,
    p.transaction_type is null as has_unmapped_type,
    case when p.is_volume_qualifying then 1 else 0 end as qualifying_count,
    case when p.is_volume_qualifying and t.transaction_state = 'COMPLETED' then 1 else 0 end as completed_qualifying_count,
    case when p.is_volume_qualifying and t.transaction_state = 'COMPLETED' then t.sent_amount else 0 end as completed_sent_amount
from {{ ref('stg_payments__transactions') }} t
left join {{ ref('transaction_type_policy') }} p on t.transaction_type = p.transaction_type
