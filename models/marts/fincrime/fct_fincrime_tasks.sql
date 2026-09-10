with matches as (
    select
        task_id,
        count(*) as candidate_count,
        case when count(*) = 1 then min(workflow_execution_id) end as inferred_workflow_execution_id
    from {{ ref('int_task_workflow_candidates') }}
    group by task_id
)

select
    t.task_id,
    t.task_type,
    t.task_state,
    t.resolution,
    t.created_at,
    t.updated_at,
    cast(t.created_at as date) as task_date,
    t.user_id,
    t.transaction_id,
    coalesce(m.candidate_count, 0) as candidate_count,
    case
        when t.has_context_conflict then 'CONFLICTING_CONTEXT'
        when t.user_id is null and t.transaction_id is null then 'UNSUPPORTED_CONTEXT'
        when coalesce(m.candidate_count, 0) = 0 then 'UNMATCHED'
        when m.candidate_count = 1 then 'UNIQUE_INFERRED'
        else 'AMBIGUOUS'
    end as match_status,
    m.inferred_workflow_execution_id,
    w.workflow_result as inferred_workflow_result,
    1 as task_count,
    case when t.task_state = 'RESOLVED' then 1 else 0 end as resolved_task_count,
    case
        when t.task_state = 'RESOLVED' and t.updated_at >= t.created_at
            then datediff('millisecond', t.created_at, t.updated_at) / 1000.0
    end as resolution_seconds
from {{ ref('int_fincrime_task_context') }} as t
left join matches as m on t.task_id = m.task_id
left join {{ ref('int_workflow_context') }} as w on m.inferred_workflow_execution_id = w.workflow_execution_id
