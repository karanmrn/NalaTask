{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='rule_execution_id',
    on_schema_change='append_new_columns',
    cluster_by=['execution_date']
) }}

-- One row per rule execution, joined to the exact rule version that ran (soft-deleted versions included).

with executions as (
    select *
    from {{ ref('stg_fincrime__rule_executions') }}
    {{ incremental_lookback('created_at') }}
)

select
    e.rule_execution_id,
    e.rule_id,
    e.workflow_execution_id,
    r.rule_name,
    r.rule_category,
    r.rule_version,
    e.rule_result,
    e.created_at,
    cast(e.created_at as date) as execution_date,
    1 as execution_count,
    case when e.rule_result = 'FAIL' then 1 else 0 end as trigger_count
from executions as e
left join {{ ref('stg_fincrime__rules') }} as r on e.rule_id = r.rule_id
