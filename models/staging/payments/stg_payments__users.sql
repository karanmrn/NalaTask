-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'users')) }}
)
select
    cast(id as varchar) as user_id,
    cast(status as varchar) as user_status,
    {{ as_variant('source') }} as source,
    cast(sender_country as varchar) as sender_country,
    cast(created as {{ dbt.type_timestamp() }}) as registered_at,
    cast(allowed as {{ dbt.type_timestamp() }}) as approved_at,
    {{ as_variant('client_properties') }} as client_properties,
    cast(used_invitation_code_id as varchar) as used_invitation_code_id,
    cast(profile_picture as varchar) as profile_picture,
    {{ as_variant('usage') }} as usage,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
