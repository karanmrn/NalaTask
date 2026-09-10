select task_date, match_status, inferred_workflow_result, resolution,
    sum(task_count) as tasks_created,
    sum(resolved_task_count) as resolved_tasks,
    {{ safe_ratio('sum(resolved_task_count)', 'sum(task_count)') }} as resolved_proportion,
    avg(resolution_seconds_proxy) as avg_resolution_seconds_proxy
from {{ ref('fct_fincrime_tasks') }}
group by task_date, match_status, inferred_workflow_result, resolution
