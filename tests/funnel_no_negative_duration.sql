{{ config(severity='warn', tags=['exploratory']) }}
select funnel_entity_id from {{ ref('fct_onboarding_funnel') }} where signup_to_first_transaction_hours < 0 or start_to_signup_hours < 0 or signup_to_kyc_hours < 0 or kyc_to_transaction_hours < 0
