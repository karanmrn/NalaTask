{{ config(severity='error', tags=['finance']) }}
select transaction_id from {{ ref('fct_transactions') }} where transaction_date < (select min(date_day) from {{ ref('metricflow_time_spine') }}) or transaction_date > (select max(date_day) from {{ ref('metricflow_time_spine') }})
