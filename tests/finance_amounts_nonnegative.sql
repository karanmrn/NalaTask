{{ config(severity='error', tags=['finance']) }}
select transaction_id from {{ ref('fct_transactions') }}
where is_volume_qualifying and (sent_amount is null or sent_amount < 0 or sent_currency is null or received_currency is null)
