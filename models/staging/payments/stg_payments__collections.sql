-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'transactions_collection')) }}
)
select
    cast(id as varchar) as collection_id,
    cast(transaction_id as varchar) as transaction_id,
    cast(account_id as varchar) as account_id,
    cast(state as varchar) as collection_state,
    cast(amount as decimal(38,8)) as amount,
    cast(currency as varchar) as currency,
    cast(to_wallet_id as varchar) as to_wallet_id,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
