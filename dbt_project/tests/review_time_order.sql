{{ config(severity='error', tags=['fincrime']) }}
select review_id from {{ ref('fct_rule_reviews') }} where reviewed_at < execution_created_at
