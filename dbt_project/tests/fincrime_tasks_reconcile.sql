{{ config(severity='error', tags=['tasks']) }}
select 'tasks_mismatch' as issue where (select count(*) from {{ ref('stg_payments__tasks') }} where service = 'fincrime') <> (select count(*) from {{ ref('fct_fincrime_tasks') }})
