-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'transactions_recipient')) }}
)
select
    cast(id as varchar) as recipient_id,
    cast(account_id as varchar) as account_id,
    cast(first_name as varchar) as first_name,
    cast(last_name as varchar) as last_name,
    cast(type as varchar) as recipient_type,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
