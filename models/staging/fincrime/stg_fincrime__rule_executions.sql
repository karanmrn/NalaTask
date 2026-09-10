-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('fincrime', 'rule_executions')) }}
)
select
    cast(id as varchar) as rule_execution_id,
    cast(rule_id as varchar) as rule_id,
    cast(workflow_execution_id as varchar) as workflow_execution_id,
    cast(result as varchar) as rule_result,
    cast(condition_result as varchar) as condition_result,
    {{ as_variant('context') }} as context,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(started_at as {{ dbt.type_timestamp() }}) as started_at,
    cast(ended_at as {{ dbt.type_timestamp() }}) as ended_at,
    cast(error as varchar) as error,
    cast(review as varchar) as review,
    cast(review_comment as varchar) as review_comment,
    cast(reviewer_id as varchar) as reviewer_id,
    cast(reviewed_at as {{ dbt.type_timestamp() }}) as reviewed_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
