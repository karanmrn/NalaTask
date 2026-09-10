-- The required duration metric is independent of the four-step strict funnel.
select cast(signup_completed_at as date) as signup_date, signup_country,
       count(signup_to_first_transaction_hours) as observed_converters,
       avg(signup_to_first_transaction_hours) as signup_to_first_transaction_hours
from {{ ref('fct_onboarding_funnel') }}
where signup_completed_at is not null
group by cast(signup_completed_at as date), signup_country
