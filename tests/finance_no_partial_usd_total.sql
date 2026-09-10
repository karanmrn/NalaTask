{{ config(severity='error', tags=['finance']) }}
select transaction_date from {{ ref('agg_transactions_daily') }} where missing_fx_transactions > 0 and completed_sent_amount_usd is not null
