{{ config(severity='error', tags=['ops', 'finance']) }}
select transaction_id from {{ ref('stg_payments__collections') }} group by transaction_id having count(*) > 1 union all select transaction_id from {{ ref('stg_payments__disbursements') }} group by transaction_id having count(*) > 1
