-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('fincrime', 'rules')) }}
)

select
    cast(id as varchar) as rule_id,
    cast(name as varchar) as rule_name,
    cast(title as varchar) as title,
    cast(description as varchar) as description,
    cast(type as varchar) as rule_type,
    cast(category as varchar) as rule_category,
    cast(team as varchar) as team,
    cast(condition as varchar) as condition,
    cast(version as decimal(38, 0)) as rule_version,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(deleted_at as {{ dbt.type_timestamp() }}) as deleted_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
