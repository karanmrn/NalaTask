{{ config(severity='error', tags=['fincrime']) }}
select 'reviews_mismatch' as issue where (select count(*) from {{ ref('stg_fincrime__reviews') }}) <> (select sum(review_count) from {{ ref('fct_rule_reviews') }})
