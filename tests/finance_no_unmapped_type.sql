{{ config(severity='error', tags=['finance']) }}
select transaction_id from {{ ref('int_transactions_classified') }}
where has_unmapped_type
