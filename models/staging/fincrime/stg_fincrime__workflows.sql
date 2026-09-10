-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('fincrime', 'workflows')) }}
)
select
    cast(id as varchar) as workflow_id,
    cast(name as varchar) as workflow_name,
    cast(title as varchar) as title,
    cast(type as varchar) as workflow_type,
    {{ as_variant('config') }} as config,
    cast(version as decimal(38,0)) as workflow_version,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(deleted_at as {{ dbt.type_timestamp() }}) as deleted_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
