-- One row per payout provider observed in disbursement attempts, with lifetime activity bounds.

select
    provider_name,
    min(created_at) as first_attempt_at,
    max(created_at) as last_attempt_at,
    count(*) as lifetime_attempts
from {{ ref('stg_payments__disbursement_attempts') }}
group by provider_name
