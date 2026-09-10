select
    review_date,
    rule_name,
    rule_category,
    sum(false_positive_count) as false_positive_reviews,
    sum(review_count) as total_formal_reviews,
    {{ safe_ratio('sum(false_positive_count)', 'sum(review_count)') }} as fincrime_false_positive_rate
from {{ ref('fct_rule_reviews') }}
group by review_date, rule_name, rule_category
