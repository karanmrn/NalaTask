{{ config(severity='error', tags=['tasks']) }}
select c.task_id from {{ ref('int_task_workflow_candidates') }} as c inner join {{ ref('int_fincrime_task_context') }} as t on c.task_id = t.task_id inner join {{ ref('int_workflow_context') }} as w on c.workflow_execution_id = w.workflow_execution_id
where w.created_at > t.created_at
