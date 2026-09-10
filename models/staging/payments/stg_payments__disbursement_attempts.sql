-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'disbursement_attempts')) }}
)
select
    cast(id as varchar) as attempt_id,
    cast(disbursement_id as varchar) as disbursement_id,
    cast(state as varchar) as attempt_state,
    cast(provider_name as varchar) as provider_name,
    cast(provider_id as varchar) as provider_id,
    cast(selection_reason as varchar) as selection_reason,
    cast(provider_error_category as varchar) as provider_error_category,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(last_updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(eta as {{ dbt.type_timestamp() }}) as eta,
    cast(max_eta as {{ dbt.type_timestamp() }}) as max_eta,
    cast(error as varchar) as error,
    cast(provider_error as varchar) as provider_error,
    cast(receipt_number as varchar) as receipt_number,
    cast(psp_account_id as varchar) as psp_account_id,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
