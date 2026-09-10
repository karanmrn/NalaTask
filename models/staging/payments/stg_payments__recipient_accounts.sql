-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as recipient_account_id,
    cast(recipient_id as varchar) as recipient_id,
    cast(type as varchar) as destination_type,
    cast(country as varchar) as country,
    cast(currency as varchar) as currency,
    cast(phone_number as varchar) as phone_number,
    cast(operator as varchar) as operator,
    cast(account_number as varchar) as account_number,
    cast(bank_code as varchar) as bank_code,
    cast(bank_name as varchar) as bank_name,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at
from {{ source('payments', 'transactions_recipient_account') }}
