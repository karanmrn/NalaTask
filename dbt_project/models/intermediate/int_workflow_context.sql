select workflow_execution_id, workflow_id, workflow_result, created_at, started_at, ended_at,
    {{ json_text('context', 'user_id') }} as user_id,
    {{ json_text('context', 'transaction_id') }} as transaction_id,
    coalesce(array_contains(to_variant('CREATE_TASK'), actions), false)
      or coalesce(array_contains(to_variant('BLOCK_USER'), actions), false)
      or coalesce(array_contains(to_variant('HOLD_TRANSACTION'), actions), false) as has_task_action
from {{ ref('stg_fincrime__workflow_executions') }}
