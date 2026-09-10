-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as rule_execution_id,
    cast(rule_id as varchar) as rule_id,
    cast(workflow_execution_id as varchar) as workflow_execution_id,
    cast(result as varchar) as rule_result,
    cast(condition_result as varchar) as condition_result,
    {{ as_variant('context') }} as context,
    cast(created_at as timestamp_ntz) as created_at,
    cast(started_at as timestamp_ntz) as started_at,
    cast(ended_at as timestamp_ntz) as ended_at,
    cast(error as varchar) as error,
    cast(review as varchar) as review,
    cast(review_comment as varchar) as review_comment,
    cast(reviewer_id as varchar) as reviewer_id,
    cast(reviewed_at as timestamp_ntz) as reviewed_at
from {{ source('fincrime', 'rule_executions') }}
