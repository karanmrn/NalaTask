{{ config(severity='error', tags=['finance']) }}
select
    rate_date,
    currency
from {{ source('reference_data', 'daily_fx_rates') }}
group by rate_date, currency
having count(*) > 1 or min(usd_per_unit) <= 0 or count(usd_per_unit) <> count(*)
