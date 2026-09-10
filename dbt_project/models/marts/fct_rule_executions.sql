select e.rule_execution_id, e.rule_id, e.workflow_execution_id,
    r.rule_name, r.rule_category, r.rule_version, e.rule_result,
    e.created_at, cast(e.created_at as date) as execution_date,
    1 as execution_count,
    case when e.rule_result = 'FAIL' then 1 else 0 end as trigger_count_proxy
from {{ ref('stg_fincrime__rule_executions') }} e
left join {{ ref('stg_fincrime__rules') }} r on e.rule_id = r.rule_id
