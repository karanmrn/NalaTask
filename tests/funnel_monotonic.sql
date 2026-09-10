{{ config(severity='warn', tags=['exploratory']) }}
select funnel_entity_id from {{ ref('fct_onboarding_funnel') }}
where ordered_transaction_count > ordered_kyc_count or ordered_kyc_count > ordered_signup_count or ordered_signup_count > started_count
