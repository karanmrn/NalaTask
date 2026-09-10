-- Two equijoins instead of a large OR join. Candidate sets are disjoint by task scope.
select
    t.task_id,
    w.workflow_execution_id
from {{ ref('int_fincrime_task_context') }} as t
inner join {{ ref('int_workflow_context') }} as w on t.transaction_id = w.transaction_id
where
    t.transaction_id is not null and not t.has_context_conflict
    and (t.user_id is null or w.user_id is null or t.user_id = w.user_id)
    and w.has_task_action
    and w.created_at <= t.created_at
    and w.created_at >= {{ dbt.dateadd('minute', '-' ~ var('task_match_window_minutes', 60), 't.created_at') }}
union all
select
    t.task_id,
    w.workflow_execution_id
from {{ ref('int_fincrime_task_context') }} as t
inner join {{ ref('int_workflow_context') }} as w on t.user_id = w.user_id
where
    t.transaction_id is null and t.user_id is not null and not t.has_context_conflict
    and w.transaction_id is null and w.has_task_action
    and w.created_at <= t.created_at
    and w.created_at >= {{ dbt.dateadd('minute', '-' ~ var('task_match_window_minutes', 60), 't.created_at') }}
