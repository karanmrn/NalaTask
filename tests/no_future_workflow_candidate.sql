{{ config(severity='error', tags=['tasks']) }}
select c.task_id from {{ ref('int_task_workflow_candidates') }} c join {{ ref('int_fincrime_task_context') }} t on c.task_id = t.task_id join {{ ref('int_workflow_context') }} w on c.workflow_execution_id = w.workflow_execution_id where w.created_at > t.created_at
