{{ config(severity='error', tags=['tasks']) }}
select task_id from {{ ref('fct_fincrime_tasks') }}
where updated_at < created_at
