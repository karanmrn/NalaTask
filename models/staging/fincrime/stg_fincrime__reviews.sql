-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as review_id,
    cast(rule_execution_id as varchar) as rule_execution_id,
    cast(reviewer_id as varchar) as reviewer_id,
    cast(review as varchar) as review_determination,
    cast(review_comment as varchar) as review_comment,
    cast(reviewed_at as timestamp_ntz) as reviewed_at
from {{ source('fincrime', 'rule_execution_reviews') }}
