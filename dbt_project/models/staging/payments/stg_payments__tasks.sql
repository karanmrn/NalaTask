-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
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
    cast(created_at as timestamp_ntz) as created_at,
    cast(last_updated_at as timestamp_ntz) as updated_at,
    cast(resolution as varchar) as resolution
from {{ source('payments', 'tasks_task') }}
