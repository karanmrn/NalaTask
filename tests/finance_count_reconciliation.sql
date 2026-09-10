{{ config(severity='error', tags=['finance']) }}
select 'count_mismatch' as issue
where (select sum(completed_transactions) from {{ ref('agg_transactions_daily') }}) <> (select sum(completed_qualifying_count) from {{ ref('fct_transactions') }})
