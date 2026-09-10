-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'transactions_disbursement')) }}
)

select
    cast(id as varchar) as disbursement_id,
    cast(transaction_id as varchar) as transaction_id,
    cast(state as varchar) as disbursement_state,
    cast(amount as decimal(38, 8)) as amount,
    cast(currency as varchar) as currency,
    cast(recipient_id as varchar) as recipient_id,
    cast(recipient_account_id as varchar) as recipient_account_id,
    cast(provider_name as varchar) as provider_name,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
