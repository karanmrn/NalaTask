{{ config(severity='error', tags=['ops']) }}
select attempt_id from {{ ref('fct_disbursement_attempts') }}
where updated_at < created_at
