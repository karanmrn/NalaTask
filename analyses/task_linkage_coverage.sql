select
    task_date,
    match_status,
    count(*) as tasks,
    {{ safe_ratio('count(*)', 'sum(count(*)) over (partition by task_date)') }} as cohort_share
from {{ ref('fct_fincrime_tasks') }}
group by task_date, match_status
