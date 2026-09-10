{{ config(severity='error', tags=['fincrime']) }}
select 'reviews_mismatch' as issue
where (select count(*) from {{ ref('stg_fincrime__rule_execution_reviews') }}) <> (select sum(review_count) from {{ ref('fct_rule_reviews') }})
