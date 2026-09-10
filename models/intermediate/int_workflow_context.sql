select
    workflow_execution_id,
    workflow_id,
    workflow_result,
    created_at,
    started_at,
    ended_at,
    {{ json_text('context', 'user_id') }} as user_id,
    {{ json_text('context', 'transaction_id') }} as transaction_id,
    {{ array_has("'CREATE_TASK'", 'actions') }}
    or {{ array_has("'BLOCK_USER'", 'actions') }}
    or {{ array_has("'HOLD_TRANSACTION'", 'actions') }} as has_task_action
from {{ ref('stg_fincrime__workflow_executions') }}
