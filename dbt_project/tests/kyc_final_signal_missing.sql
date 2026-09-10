{{ config(severity='warn', tags=['exploratory']) }}
select 'KYC contract unconfirmed: no final signal observed' as issue where exists (select 1 from {{ ref('int_onboarding_events') }} where event_type = 'kyc_step.completed') and not exists (select 1 from {{ ref('int_onboarding_events') }} where is_final_kyc_event)
