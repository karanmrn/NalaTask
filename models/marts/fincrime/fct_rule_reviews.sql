select
    v.review_id,
    v.rule_execution_id,
    e.rule_id,
    e.rule_name,
    e.rule_category,
    e.rule_version,
    v.review_determination,
    v.reviewed_at,
    cast(v.reviewed_at as date) as review_date,
    e.created_at as execution_created_at,
    1 as review_count,
    case when v.review_determination = 'FALSE_POSITIVE' then 1 else 0 end as false_positive_count,
    case
        when v.reviewed_at >= e.created_at
            then datediff('millisecond', e.created_at, v.reviewed_at) / 1000.0
    end as review_seconds
from {{ ref('stg_fincrime__rule_execution_reviews') }} as v
left join {{ ref('fct_rule_executions') }} as e on v.rule_execution_id = e.rule_execution_id
