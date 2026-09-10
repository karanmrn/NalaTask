-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as collection_id,
    cast(transaction_id as varchar) as transaction_id,
    cast(account_id as varchar) as account_id,
    cast(state as varchar) as collection_state,
    cast(amount as number(38,8)) as amount,
    cast(currency as varchar) as currency,
    cast(to_wallet_id as varchar) as to_wallet_id,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at
from {{ source('payments', 'transactions_collection') }}
