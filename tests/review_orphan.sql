{{ config(severity='error', tags=['fincrime']) }}
select review_id from {{ ref('fct_rule_reviews') }}
where rule_id is null
