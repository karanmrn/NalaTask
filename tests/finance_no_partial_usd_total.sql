{{ config(severity='error', tags=['finance']) }}
select completed_date from {{ ref('agg_finance_volume_daily') }}
where missing_fx_transactions > 0 and completed_sent_amount_usd is not null
