-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'users_account')) }}
)
select
    cast(id as varchar) as account_id,
    cast(owner_id as varchar) as owner_user_id,
    cast(name as varchar) as account_name,
    cast(type as varchar) as account_type,
    cast(status as varchar) as account_status,
    {{ as_variant('features') }} as features,
    cast(created as {{ dbt.type_timestamp() }}) as created_at,
    cast(last_updated as {{ dbt.type_timestamp() }}) as updated_at,
    cast(profile_id as varchar) as profile_id,
    cast(limit_level as varchar) as limit_level,
    {{ as_variant('client_properties') }} as client_properties,
    cast(deleted as {{ dbt.type_timestamp() }}) as deleted_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
