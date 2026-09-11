{{ config(severity='error', tags=['finance']) }}
with spine as (
    select
        min(date_day) as min_day,
        max(date_day) as max_day
    from {{ ref('metricflow_time_spine') }}
)

select t.transaction_id
from {{ ref('fct_transactions') }} as t
cross join spine
where t.transaction_date < spine.min_day or t.transaction_date > spine.max_day
