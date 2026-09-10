{% snapshot snap_transaction_state %}
{{ config(
    unique_key='transaction_id',
    strategy='timestamp',
    updated_at='updated_at',
    tags=['production']
) }}
-- Type 2 history of transaction state. The source keeps only the current row; this snapshot
-- records every state transition dbt observes so completion, failure and hold durations can be
-- measured from real timestamps instead of "last update" proxies.
select transaction_id, transaction_state, updated_at
from {{ ref('stg_payments__transactions') }}
{% endsnapshot %}
