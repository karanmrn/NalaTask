-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('fincrime', 'workflow_executions')) }}
)
select
    cast(id as varchar) as workflow_execution_id,
    cast(workflow_id as varchar) as workflow_id,
    cast(result as varchar) as workflow_result,
    {{ as_variant('context') }} as context,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(started_at as {{ dbt.type_timestamp() }}) as started_at,
    cast(ended_at as {{ dbt.type_timestamp() }}) as ended_at,
    cast(error as varchar) as error,
    {{ as_variant('actions') }} as actions,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
