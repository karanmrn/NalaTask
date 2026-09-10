{{ config(severity='error', tags=['finance', 'publication_gate']) }}
select transaction_id from {{ ref('fct_transactions') }} where is_missing_fx
