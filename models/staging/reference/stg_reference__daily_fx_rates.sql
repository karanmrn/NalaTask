-- Finance-approved daily USD rates. Not one of the three supplied sources; a declared dependency.
select
    cast(rate_date as date) as rate_date,
    cast(currency as varchar) as currency,
    cast(usd_per_unit as decimal(38,12)) as usd_per_unit,
    cast(rate_source as varchar) as rate_source
from {{ source('reference_data', 'daily_fx_rates') }}
