-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as disbursement_id,
    cast(transaction_id as varchar) as transaction_id,
    cast(state as varchar) as disbursement_state,
    cast(amount as number(38,8)) as amount,
    cast(currency as varchar) as currency,
    cast(recipient_id as varchar) as recipient_id,
    cast(recipient_account_id as varchar) as recipient_account_id,
    cast(provider_name as varchar) as provider_name,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at
from {{ source('payments', 'transactions_disbursement') }}
