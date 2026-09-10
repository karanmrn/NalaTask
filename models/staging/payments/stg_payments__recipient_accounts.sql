-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'transactions_recipient_account')) }}
)
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
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
