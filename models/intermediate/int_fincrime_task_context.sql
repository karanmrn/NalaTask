with extracted as (
    select
        task_id,
        task_type,
        task_state,
        resolution,
        created_at,
        updated_at,
        case when task_type = 'transaction_review' then {{ json_text('associated_ids', '[0]') }} end as typed_transaction_id,
        case
            when task_type = 'user_review' then {{ json_text('associated_ids', '[0]') }}
            when task_type = 'transaction_review' then {{ json_text('associated_ids', '[2]') }}
        end as typed_user_id,
        {{ json_text('content', 'disbursement_id') }} as content_disbursement_id
    from {{ ref('stg_payments__tasks') }}
    where service = 'fincrime'
),

anchored as (
    select
        t.*,
        d.transaction_id as disbursement_transaction_id,
        coalesce(t.typed_transaction_id, d.transaction_id) as transaction_id
    from extracted as t
    left join {{ ref('stg_payments__disbursements') }} as d on t.content_disbursement_id = d.disbursement_id
)

select
    a.task_id,
    a.task_type,
    a.task_state,
    a.resolution,
    a.created_at,
    a.updated_at,
    a.transaction_id,
    coalesce(a.typed_user_id, tx.user_id) as user_id,
    (
        a.typed_transaction_id is not null and a.disbursement_transaction_id is not null
        and a.typed_transaction_id <> a.disbursement_transaction_id
    )
    or (a.typed_user_id is not null and tx.user_id is not null and a.typed_user_id <> tx.user_id)
        as has_context_conflict
from anchored as a
left join {{ ref('stg_payments__transactions') }} as tx on a.transaction_id = tx.transaction_id
