{{ config(severity='error', tags=['tasks']) }}
select task_id from {{ ref('fct_fincrime_tasks') }} where (candidate_count <> 1 and inferred_workflow_execution_id is not null) or (match_status <> 'UNIQUE_INFERRED' and inferred_workflow_result is not null)
