-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as workflow_execution_id,
    cast(workflow_id as varchar) as workflow_id,
    cast(result as varchar) as workflow_result,
    {{ as_variant('context') }} as context,
    cast(created_at as timestamp_ntz) as created_at,
    cast(started_at as timestamp_ntz) as started_at,
    cast(ended_at as timestamp_ntz) as ended_at,
    cast(error as varchar) as error,
    {{ as_variant('actions') }} as actions
from {{ source('fincrime', 'workflow_executions') }}
