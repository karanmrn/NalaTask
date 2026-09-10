with e as (
    select execution_date as activity_date, rule_id, rule_name, rule_category, rule_version,
           sum(execution_count) as executions, sum(trigger_count) as triggers
    from {{ ref('fct_rule_executions') }}
    group by execution_date, rule_id, rule_name, rule_category, rule_version
), r as (
    select review_date as activity_date, rule_id,
           sum(review_count) as reviews, sum(false_positive_count) as false_positives,
           avg(review_seconds) as avg_review_seconds
    from {{ ref('fct_rule_reviews') }}
    group by review_date, rule_id
), keys as (
    select activity_date, rule_id from e union select activity_date, rule_id from r
)
select k.activity_date, k.rule_id, d.rule_name, d.rule_category, d.rule_version,
    coalesce(e.executions, 0) as executions, coalesce(e.triggers, 0) as triggers,
    {{ safe_ratio('e.triggers', 'e.executions') }} as trigger_rate,
    coalesce(r.reviews, 0) as reviews, coalesce(r.false_positives, 0) as false_positives,
    {{ safe_ratio('r.false_positives', 'r.reviews') }} as false_positive_rate,
    r.avg_review_seconds
from keys k
left join e on k.activity_date = e.activity_date and k.rule_id = e.rule_id
left join r on k.activity_date = r.activity_date and k.rule_id = r.rule_id
left join {{ ref('stg_fincrime__rules') }} d on k.rule_id = d.rule_id
