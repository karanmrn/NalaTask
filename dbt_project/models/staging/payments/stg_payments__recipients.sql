-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as recipient_id,
    cast(account_id as varchar) as account_id,
    cast(first_name as varchar) as first_name,
    cast(last_name as varchar) as last_name,
    cast(type as varchar) as recipient_type,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at
from {{ source('payments', 'transactions_recipient') }}
