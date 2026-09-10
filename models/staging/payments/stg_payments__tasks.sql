-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'tasks_task')) }}
)
select
    cast(id as varchar) as task_id,
    cast(service as varchar) as service,
    cast(type as varchar) as task_type,
    cast(state as varchar) as task_state,
    cast(priority as varchar) as priority,
    cast(staff_id as varchar) as staff_id,
    cast(assignee_id as varchar) as assignee_id,
    {{ as_variant('associated_ids') }} as associated_ids,
    {{ as_variant('content') }} as content,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(last_updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(resolution as varchar) as resolution,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
